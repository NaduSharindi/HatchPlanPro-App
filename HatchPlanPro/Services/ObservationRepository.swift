//
//  ObservationRepository.swift
//  HatchPlanPro
//
//  Offline-first store for batch observations: Core Data locally, mirrored to
//  the Firestore subcollection hatchPlans/{planID}/observations.
//

import Foundation
import Combine
import CoreData
import UIKit
import FirebaseFirestore

final class ObservationRepository: ObservableObject {
    static let shared = ObservationRepository()

    /// Observations keyed by plan ID, newest first.
    @Published private(set) var observationsByPlan: [String: [BatchObservation]] = [:]

    private var listeners: [String: ListenerRegistration] = [:]
    private var context: NSManagedObjectContext { PersistenceController.shared.container.viewContext }

    private init() {
        reloadFromStore()
        flushPendingWrites()
    }

    func observations(for planID: String) -> [BatchObservation] {
        observationsByPlan[planID] ?? []
    }

    // MARK: - Writes

    func save(_ observation: BatchObservation) {
        var observation = observation
        observation.updatedAt = Date()
        upsertLocal(observation, needsSync: true)
        saveContext()
        reloadFromStore()
        push(observation)
    }

    func delete(_ observation: BatchObservation) {
        if let managed = fetchManaged(id: observation.id) {
            context.delete(managed)
            saveContext()
            reloadFromStore()
        }
        collection(for: observation.planID).document(observation.id).delete { error in
            if let error { print("ObservationRepository: delete failed — \(error.localizedDescription)") }
        }
    }

    func flushPendingWrites() {
        let request: NSFetchRequest<CDObservation> = CDObservation.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES AND planID != nil")
        ((try? context.fetch(request)) ?? []).compactMap { Self.record(from: $0) }.forEach { push($0) }
    }

    private func push(_ observation: BatchObservation) {
        collection(for: observation.planID).document(observation.id).setData(Self.encode(observation)) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    print("ObservationRepository: push failed — \(error.localizedDescription)")
                    return
                }
                guard let self, let managed = self.fetchManaged(id: observation.id),
                      managed.updatedAt == observation.updatedAt else { return }
                managed.needsSync = false
                self.saveContext()
            }
        }
    }

    // MARK: - Listening

    /// Attaches a live listener for one batch while its detail screen is open.
    func startListening(planID: String) {
        guard listeners[planID] == nil else { return }
        listeners[planID] = collection(for: planID).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                print("ObservationRepository: listener error — \(error.localizedDescription)")
                self.listeners[planID] = nil
                return
            }
            guard let snapshot else { return }
            for change in snapshot.documentChanges {
                let document = change.document
                switch change.type {
                case .added, .modified:
                    guard let remote = Self.decode(id: document.documentID, planID: planID, data: document.data()) else { continue }
                    let local = self.fetchManaged(id: remote.id)
                    if let local, (local.updatedAt ?? .distantPast) >= remote.updatedAt { continue }
                    self.upsertLocal(remote, needsSync: false)
                case .removed:
                    if !document.metadata.hasPendingWrites, let managed = self.fetchManaged(id: document.documentID) {
                        self.context.delete(managed)
                    }
                }
            }
            self.saveContext()
            self.reloadFromStore()
        }
    }

    func stopListening(planID: String) {
        listeners[planID]?.remove()
        listeners[planID] = nil
    }

    // MARK: - Core Data

    private func collection(for planID: String) -> CollectionReference {
        Firestore.firestore().collection("hatchPlans").document(planID).collection("observations")
    }

    private func reloadFromStore() {
        let request: NSFetchRequest<CDObservation> = CDObservation.fetchRequest()
        request.predicate = NSPredicate(format: "planID != nil")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let records = ((try? context.fetch(request)) ?? []).compactMap { Self.record(from: $0) }
        observationsByPlan = Dictionary(grouping: records, by: \.planID)
    }

    private func fetchManaged(id: String) -> CDObservation? {
        let request: NSFetchRequest<CDObservation> = CDObservation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func upsertLocal(_ observation: BatchObservation, needsSync: Bool) {
        let managed = fetchManaged(id: observation.id) ?? CDObservation(context: context)
        managed.id = observation.id
        managed.planID = observation.planID
        managed.batchID = observation.planID
        managed.category = observation.category.rawValue
        managed.note = observation.note
        managed.authorName = observation.authorName
        managed.authorRole = observation.authorRole
        managed.authorUID = observation.authorUID
        managed.createdAt = observation.createdAt
        managed.updatedAt = observation.updatedAt
        managed.photoData = try? PropertyListEncoder().encode(observation.photos)
        managed.needsSync = needsSync
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do { try context.save() } catch {
            print("ObservationRepository: save failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Mapping

    private static func record(from managed: CDObservation) -> BatchObservation? {
        guard let id = managed.id, let planID = managed.planID else { return nil }
        let photos = managed.photoData.flatMap { try? PropertyListDecoder().decode([Data].self, from: $0) } ?? []
        return BatchObservation(
            id: id,
            planID: planID,
            category: ObservationCategory(rawValue: managed.category ?? "") ?? .generalNote,
            note: managed.note ?? "",
            authorName: managed.authorName ?? "",
            authorRole: managed.authorRole ?? "",
            authorUID: managed.authorUID,
            createdAt: managed.createdAt ?? Date(),
            updatedAt: managed.updatedAt ?? Date(),
            photos: photos
        )
    }

    private static func encode(_ observation: BatchObservation) -> [String: Any] {
        var data: [String: Any] = [
            "category": observation.category.rawValue,
            "note": observation.note,
            "authorName": observation.authorName,
            "authorRole": observation.authorRole,
            "createdAt": Timestamp(date: observation.createdAt),
            "updatedAt": Timestamp(date: observation.updatedAt),
            "photos": observation.photos
        ]
        data["authorUID"] = observation.authorUID
        return data
    }

    private static func decode(id: String, planID: String, data: [String: Any]) -> BatchObservation? {
        guard let note = data["note"] as? String,
              let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() else { return nil }
        return BatchObservation(
            id: id,
            planID: planID,
            category: ObservationCategory(rawValue: data["category"] as? String ?? "") ?? .generalNote,
            note: note,
            authorName: data["authorName"] as? String ?? "",
            authorRole: data["authorRole"] as? String ?? "",
            authorUID: data["authorUID"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? updatedAt,
            updatedAt: updatedAt,
            photos: data["photos"] as? [Data] ?? []
        )
    }

    /// Downscales a photo so four fit comfortably in one Firestore document.
    static func compressed(_ image: UIImage) -> Data? {
        CertificateOCRService.compressedRecord(of: image, maxDimension: 800)
    }
}
