//
//  HatchPlanRepository.swift
//  HatchPlanPro
//
//  Offline-first store for hatch plans. Core Data is the single source of
//  truth for the UI; every write is saved locally first (flagged needsSync),
//  then pushed to the Firestore `hatchPlans` collection. A snapshot listener
//  merges changes made on other devices using last-writer-wins on updatedAt.
//

import Foundation
import Combine
import CoreData
import FirebaseFirestore

final class HatchPlanRepository: ObservableObject {
    static let shared = HatchPlanRepository()

    @Published private(set) var plans: [HatchPlanRecord] = []
    @Published private(set) var lastSyncError: String?
    @Published private(set) var pendingSyncCount = 0

    /// Status changes that arrived from another device, with the status this
    /// device knew before. Drives cross-device approval alerts.
    let remoteStatusChanges = PassthroughSubject<(plan: HatchPlanRecord, previous: BatchStatus?), Never>()

    private lazy var collection = Firestore.firestore().collection("hatchPlans")
    private var listener: ListenerRegistration?
    private var hasReceivedInitialSnapshot = false

    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }

    private init() {
        reloadFromStore()
    }

    // MARK: - Reads

    func plan(withID id: String) -> HatchPlanRecord? {
        plans.first { $0.id == id }
    }

    // MARK: - Writes

    /// Saves locally, then pushes to Firestore. Safe to call offline.
    func save(_ plan: HatchPlanRecord) {
        var plan = plan
        plan.updatedAt = Date()
        upsertLocal(plan, needsSync: true)
        reloadFromStore()
        push(plan)
    }

    /// Re-sends anything saved while offline or rejected by the server.
    func flushPendingWrites() {
        let request: NSFetchRequest<CDHatchPlan> = CDHatchPlan.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        let pending = (try? context.fetch(request)) ?? []
        pending.compactMap { Self.record(from: $0) }.forEach { push($0) }
    }

    private func push(_ plan: HatchPlanRecord) {
        collection.document(plan.id).setData(Self.encode(plan)) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    self.lastSyncError = error.localizedDescription
                    print("HatchPlanRepository: push failed for \(plan.batchID) — \(error.localizedDescription)")
                    return
                }
                self.lastSyncError = nil
                self.markSynced(id: plan.id, version: plan.updatedAt)
            }
        }
    }

    // MARK: - Remote Listener

    func startListening() {
        guard listener == nil else { return }
        flushPendingWrites()

        listener = collection.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                self.lastSyncError = error.localizedDescription
                print("HatchPlanRepository: listener error — \(error.localizedDescription)")
                // Firestore drops a listener after an error; allow startListening() to re-attach.
                self.listener = nil
                self.hasReceivedInitialSnapshot = false
                // Cloud unavailable (offline or rules): keep the farm floor usable.
                self.seedDemoDataIfNeeded(remoteIsEmpty: true)
                return
            }
            guard let snapshot else { return }

            let isInitial = !self.hasReceivedInitialSnapshot
            self.hasReceivedInitialSnapshot = true

            for change in snapshot.documentChanges {
                let document = change.document
                switch change.type {
                case .added, .modified:
                    guard let remote = Self.decode(id: document.documentID, data: document.data()) else { continue }
                    self.mergeRemote(remote,
                                     fromThisDevice: document.metadata.hasPendingWrites,
                                     isInitialSnapshot: isInitial)
                case .removed:
                    self.deleteLocal(id: document.documentID)
                }
            }

            self.saveContext()
            self.reloadFromStore()

            if isInitial {
                self.seedDemoDataIfNeeded(remoteIsEmpty: snapshot.documents.isEmpty)
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        hasReceivedInitialSnapshot = false
    }

    private func mergeRemote(_ remote: HatchPlanRecord, fromThisDevice: Bool, isInitialSnapshot: Bool) {
        let local = fetchManagedPlan(id: remote.id)
        let localVersion = local?.updatedAt ?? .distantPast

        // Our own unsent edit is newer than the cloud copy: keep it.
        if let local, local.needsSync, localVersion >= remote.updatedAt { return }
        // Already up to date.
        if let local, !local.needsSync, localVersion >= remote.updatedAt { return }

        let previous = local.flatMap { $0.status }.flatMap { BatchStatus(storedValue: $0) }
        upsertLocal(remote, needsSync: false, save: false)

        guard !fromThisDevice, previous != remote.status else { return }
        // A first launch downloads every plan; only announce genuinely new events.
        if previous == nil && isInitialSnapshot { return }
        remoteStatusChanges.send((remote, previous))
    }

    // MARK: - Core Data

    private func reloadFromStore() {
        let request: NSFetchRequest<CDHatchPlan> = CDHatchPlan.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        let stored = (try? context.fetch(request)) ?? []
        plans = stored.compactMap { Self.record(from: $0) }
        pendingSyncCount = stored.filter(\.needsSync).count
    }

    private func fetchManagedPlan(id: String) -> CDHatchPlan? {
        let request: NSFetchRequest<CDHatchPlan> = CDHatchPlan.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func upsertLocal(_ plan: HatchPlanRecord, needsSync: Bool, save: Bool = true) {
        let managed = fetchManagedPlan(id: plan.id) ?? CDHatchPlan(context: context)
        Self.apply(plan, to: managed)
        managed.needsSync = needsSync
        if save { saveContext() }
    }

    private func markSynced(id: String, version: Date) {
        guard let managed = fetchManagedPlan(id: id),
              managed.updatedAt == version else { return }
        managed.needsSync = false
        saveContext()
        reloadFromStore()
    }

    private func deleteLocal(id: String) {
        guard let managed = fetchManagedPlan(id: id) else { return }
        context.delete(managed)
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("HatchPlanRepository: save failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Mapping

    private static func apply(_ plan: HatchPlanRecord, to managed: CDHatchPlan) {
        managed.id = plan.id
        managed.batchID = plan.batchID
        managed.breed = plan.breed.rawValue
        managed.flockID = plan.flockID
        managed.flockAgeWeeks = Int16(plan.flockAgeWeeks)
        managed.siteID = plan.siteID
        managed.targetChicks = Int32(plan.targetChicks)
        managed.safetyBuffer = plan.safetyBuffer
        managed.standardHatchability = plan.standardHatchability
        managed.requiredEggs = Int32(plan.requiredEggs)
        managed.setterTrays = Int32(plan.setterTrays)
        managed.plannedSetDate = plan.plannedSetDate
        managed.status = plan.status.rawValue
        managed.createdBy = plan.createdBy
        managed.createdByUID = plan.createdByUID
        managed.createdAt = plan.createdAt
        managed.updatedAt = plan.updatedAt
        managed.submittedAt = plan.submittedAt
        managed.reviewedBy = plan.reviewedBy
        managed.reviewedAt = plan.reviewedAt
        managed.approvalSignature = plan.approvalSignature
        managed.rejectionReason = plan.rejectionReason
        managed.certificateText = plan.certificateText
        managed.certificateImage = plan.certificateImage
        managed.ocrConfidence = plan.ocrConfidence.map { NSNumber(value: $0) }
        managed.executedAt = plan.executedAt
        managed.calendarEventIDs = plan.calendarEventIDs.joined(separator: "|")
        managed.actualChicks = plan.actualChicks.map { NSNumber(value: $0) }
        managed.closedAt = plan.closedAt
        managed.closingNotes = plan.closingNotes
    }

    private static func record(from managed: CDHatchPlan) -> HatchPlanRecord? {
        guard let id = managed.id,
              let batchID = managed.batchID,
              let statusRaw = managed.status,
              let status = BatchStatus(storedValue: statusRaw) else { return nil }

        let calculation = ProductionCalculation(
            targetChicks: Int(managed.targetChicks),
            safetyBuffer: managed.safetyBuffer,
            standardHatchability: managed.standardHatchability,
            requiredEggs: Int(managed.requiredEggs),
            setterTrays: Int(managed.setterTrays)
        )
        var plan = HatchPlanRecord(
            id: id,
            batchID: batchID,
            breed: PoultryBreed(rawValue: managed.breed ?? "") ?? .ross308,
            flockID: managed.flockID ?? "",
            flockAgeWeeks: Int(managed.flockAgeWeeks),
            siteID: managed.siteID ?? HatcherySite.all[0].id,
            plannedSetDate: managed.plannedSetDate ?? Date(),
            calculation: calculation,
            createdBy: managed.createdBy ?? "Supervisor",
            createdByUID: managed.createdByUID,
            createdAt: managed.createdAt ?? Date()
        )
        plan.status = status
        plan.updatedAt = managed.updatedAt ?? plan.createdAt
        plan.submittedAt = managed.submittedAt
        plan.reviewedBy = managed.reviewedBy
        plan.reviewedAt = managed.reviewedAt
        plan.approvalSignature = managed.approvalSignature
        plan.rejectionReason = managed.rejectionReason
        plan.certificateText = managed.certificateText
        plan.certificateImage = managed.certificateImage
        plan.ocrConfidence = managed.ocrConfidence?.doubleValue
        plan.executedAt = managed.executedAt
        plan.calendarEventIDs = (managed.calendarEventIDs ?? "").split(separator: "|").map(String.init)
        plan.actualChicks = managed.actualChicks?.intValue
        plan.closedAt = managed.closedAt
        plan.closingNotes = managed.closingNotes
        return plan
    }

    static func encode(_ plan: HatchPlanRecord) -> [String: Any] {
        var data: [String: Any] = [
            "batchID": plan.batchID,
            "breed": plan.breed.rawValue,
            "flockID": plan.flockID,
            "flockAgeWeeks": plan.flockAgeWeeks,
            "siteID": plan.siteID,
            "targetChicks": plan.targetChicks,
            "safetyBuffer": plan.safetyBuffer,
            "standardHatchability": plan.standardHatchability,
            "requiredEggs": plan.requiredEggs,
            "setterTrays": plan.setterTrays,
            "plannedSetDate": Timestamp(date: plan.plannedSetDate),
            "status": plan.status.rawValue,
            "createdBy": plan.createdBy,
            "createdAt": Timestamp(date: plan.createdAt),
            "updatedAt": Timestamp(date: plan.updatedAt),
            "calendarEventIDs": plan.calendarEventIDs
        ]
        data["createdByUID"] = plan.createdByUID
        data["submittedAt"] = plan.submittedAt.map(Timestamp.init(date:))
        data["reviewedBy"] = plan.reviewedBy
        data["reviewedAt"] = plan.reviewedAt.map(Timestamp.init(date:))
        data["approvalSignature"] = plan.approvalSignature
        data["rejectionReason"] = plan.rejectionReason
        data["certificateText"] = plan.certificateText
        data["certificateImage"] = plan.certificateImage
        data["ocrConfidence"] = plan.ocrConfidence
        data["executedAt"] = plan.executedAt.map(Timestamp.init(date:))
        data["actualChicks"] = plan.actualChicks
        data["closedAt"] = plan.closedAt.map(Timestamp.init(date:))
        data["closingNotes"] = plan.closingNotes
        return data
    }

    static func decode(id: String, data: [String: Any]) -> HatchPlanRecord? {
        func date(_ key: String) -> Date? { (data[key] as? Timestamp)?.dateValue() }
        func int(_ key: String) -> Int? { (data[key] as? NSNumber)?.intValue }
        func double(_ key: String) -> Double? { (data[key] as? NSNumber)?.doubleValue }

        guard let batchID = data["batchID"] as? String,
              let statusRaw = data["status"] as? String,
              let status = BatchStatus(storedValue: statusRaw),
              let targetChicks = int("targetChicks"),
              let requiredEggs = int("requiredEggs") else { return nil }

        let calculation = ProductionCalculation(
            targetChicks: targetChicks,
            safetyBuffer: double("safetyBuffer") ?? 0,
            standardHatchability: double("standardHatchability") ?? 0.85,
            requiredEggs: requiredEggs,
            setterTrays: int("setterTrays") ?? 0
        )
        var plan = HatchPlanRecord(
            id: id,
            batchID: batchID,
            breed: PoultryBreed(rawValue: data["breed"] as? String ?? "") ?? .ross308,
            flockID: data["flockID"] as? String ?? "",
            flockAgeWeeks: int("flockAgeWeeks") ?? 34,
            siteID: data["siteID"] as? String ?? HatcherySite.all[0].id,
            plannedSetDate: date("plannedSetDate") ?? Date(),
            calculation: calculation,
            createdBy: data["createdBy"] as? String ?? "Supervisor",
            createdByUID: data["createdByUID"] as? String,
            createdAt: date("createdAt") ?? Date()
        )
        plan.status = status
        plan.updatedAt = date("updatedAt") ?? plan.createdAt
        plan.submittedAt = date("submittedAt")
        plan.reviewedBy = data["reviewedBy"] as? String
        plan.reviewedAt = date("reviewedAt")
        plan.approvalSignature = data["approvalSignature"] as? String
        plan.rejectionReason = data["rejectionReason"] as? String
        plan.certificateText = data["certificateText"] as? String
        plan.certificateImage = data["certificateImage"] as? Data
        plan.ocrConfidence = double("ocrConfidence")
        plan.executedAt = date("executedAt")
        plan.calendarEventIDs = data["calendarEventIDs"] as? [String] ?? []
        plan.actualChicks = int("actualChicks")
        plan.closedAt = date("closedAt")
        plan.closingNotes = data["closingNotes"] as? String
        return plan
    }

    // MARK: - Demo Data

    private static let demoSeededKey = "hatchplan.demoPlansSeeded"

    /// Seeds a realistic history the first time the app runs against an empty
    /// backend, so dashboards and charts have data to show. Deterministic IDs
    /// keep two devices seeding at once from duplicating records.
    private func seedDemoDataIfNeeded(remoteIsEmpty: Bool) {
        guard remoteIsEmpty, plans.isEmpty,
              !UserDefaults.standard.bool(forKey: Self.demoSeededKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.demoSeededKey)
        DemoPlanFactory.makePlans().forEach(save)
    }
}

// MARK: - Demo Plan Factory

enum DemoPlanFactory {
    static func makePlans(now: Date = Date()) -> [HatchPlanRecord] {
        let supervisor = "Supervisor Nadunika"
        let manager = "Manager Aruni"
        let calendar = Calendar.current

        func day(_ offset: Int, hour: Int = 8) -> Date {
            let base = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) ?? now
            return calendar.date(byAdding: .hour, value: hour, to: base) ?? base
        }

        func plan(_ number: Int, breed: PoultryBreed, flock: String, age: Int, site: String,
                  target: Int, buffer: Double, setOffset: Int) -> HatchPlanRecord {
            let input = ProductionInput(targetChicks: target, breed: breed, flockAgeWeeks: age,
                                        safetyBuffer: buffer, siteCapacity: HatcherySite.site(withID: site).setterCapacity)
            let calculation = ProductionCalculator.calculate(input)!
            var record = HatchPlanRecord(
                id: "demo-B\(number)",
                batchID: "#B\(number)",
                breed: breed,
                flockID: flock,
                flockAgeWeeks: age,
                siteID: site,
                plannedSetDate: day(setOffset),
                calculation: calculation,
                createdBy: supervisor,
                createdAt: day(setOffset - 2, hour: 9)
            )
            record.submittedAt = record.createdAt
            record.certificateText = "FLOCK ID: \(flock)\nAGE: \(age) WEEKS\nSTRAIN: \(breed.rawValue.uppercased())"
            return record
        }

        func approve(_ record: inout HatchPlanRecord) {
            record.status = .approvedReady
            record.reviewedBy = manager
            record.reviewedAt = record.createdAt.addingTimeInterval(3 * 3600)
            record.approvalSignature = "\(manager) • Face ID • \(record.reviewedAt!.formatted(.iso8601))"
        }

        func execute(_ record: inout HatchPlanRecord) {
            approve(&record)
            record.status = .active
            record.executedAt = record.plannedSetDate
        }

        func close(_ record: inout HatchPlanRecord, performance: Double) {
            execute(&record)
            record.status = .completed
            record.actualChicks = Int(Double(record.requiredEggs) * record.standardHatchability * performance)
            record.closedAt = ProductionCalculator.hatchDate(from: record.plannedSetDate)
            record.closingNotes = performance >= 1
                ? "Uniform hatch window; chick quality grade A."
                : "Humidity fluctuation in the final 48 hours reduced the pull."
        }

        var plans: [HatchPlanRecord] = []

        let completedSpecs: [(Int, PoultryBreed, String, Int, String, Int, Double, Int, Double)] = [
            (1001, .ross308, "F-902", 34, "meegoda", 12_000, 0.05, -52, 1.02),
            (1004, .cobb500, "F-815", 41, "kosgama", 9_500, 0.06, -47, 0.97),
            (1007, .ross308, "F-722", 33, "meegoda", 14_000, 0.05, -43, 1.01),
            (1009, .hubbard, "F-640", 48, "halwatura", 6_000, 0.08, -38, 0.93),
            (1012, .cobb500, "F-818", 36, "kosgama", 11_000, 0.05, -34, 1.03),
            (1015, .ross308, "F-905", 31, "meegoda", 13_500, 0.04, -30, 0.99),
            (1018, .ross308, "F-906", 38, "meegoda", 12_500, 0.05, -27, 1.01),
            (1020, .cobb500, "F-820", 44, "kosgama", 10_000, 0.07, -24, 0.96)
        ]
        for spec in completedSpecs {
            var record = plan(spec.0, breed: spec.1, flock: spec.2, age: spec.3, site: spec.4,
                              target: spec.5, buffer: spec.6, setOffset: spec.7)
            close(&record, performance: spec.8)
            plans.append(record)
        }

        var active1 = plan(1022, breed: .ross308, flock: "F-910", age: 35, site: "meegoda", target: 12_500, buffer: 0.05, setOffset: -19)
        execute(&active1)
        var active2 = plan(1023, breed: .cobb500, flock: "F-822", age: 39, site: "kosgama", target: 9_800, buffer: 0.05, setOffset: -6)
        execute(&active2)
        var approved = plan(1028, breed: .cobb500, flock: "F-824", age: 30, site: "kosgama", target: 9_800, buffer: 0.05, setOffset: 1)
        approve(&approved)
        var pending1 = plan(1024, breed: .ross308, flock: "F-912", age: 34, site: "meegoda", target: 12_500, buffer: 0.05, setOffset: 2)
        pending1.status = .pendingReview
        var pending2 = plan(1025, breed: .hubbard, flock: "F-644", age: 46, site: "halwatura", target: 7_500, buffer: 0.08, setOffset: 3)
        pending2.status = .pendingReview
        var rejected = plan(1021, breed: .lohmannBrown, flock: "F-301", age: 58, site: "halwatura", target: 11_200, buffer: 0.02, setOffset: 2)
        rejected.status = .rejected
        rejected.reviewedBy = manager
        rejected.reviewedAt = rejected.createdAt.addingTimeInterval(5400)
        rejected.rejectionReason = "Flock F-301 is past 55 weeks and the 2% buffer is too thin. Raise the buffer or source from a younger flock."

        plans += [active1, active2, approved, pending1, pending2, rejected]
        return plans
    }
}
