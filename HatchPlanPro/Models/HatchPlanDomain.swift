//
//  HatchPlanDomain.swift
//  HatchPlanPro
//
//  The batch lifecycle state machine and the single record that carries a
//  batch through Planning → Verification → Documentation → Execution → Closing.
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Batch Lifecycle

/// Lifecycle states for a hatch batch. Transitions are enforced by
/// `canTransition(to:)` so a batch cannot be executed before approval or
/// closed before it has been set.
enum BatchStatus: String, Codable, CaseIterable {
    case draft = "DRAFT"
    case pendingReview = "PENDING"
    case approvedReady = "APPROVED"
    case rejected = "REJECTED"
    case active = "ACTIVE"
    case completed = "COMPLETED"

    /// Accepts values written by earlier builds ("SYNCED" meant executed).
    init?(storedValue: String) {
        if storedValue == "SYNCED" {
            self = .active
        } else {
            self.init(rawValue: storedValue)
        }
    }

    var allowedTransitions: Set<BatchStatus> {
        switch self {
        case .draft:
            return [.pendingReview]
        case .pendingReview:
            return [.approvedReady, .rejected]
        case .rejected:
            return [.pendingReview, .draft]
        case .approvedReady:
            return [.active]
        case .active:
            return [.completed]
        case .completed:
            return []
        }
    }

    func canTransition(to next: BatchStatus) -> Bool {
        allowedTransitions.contains(next)
    }

    var displayName: String {
        switch self {
        case .active:
            return "INCUBATING"
        default:
            return rawValue
        }
    }

    var color: Color {
        switch self {
        case .draft:
            return Color(hex: "#7A7A7A")
        case .pendingReview:
            return Color(hex: "#FFA500")
        case .approvedReady:
            return .hatchGreen
        case .rejected:
            return Color(hex: "#FF6B6B")
        case .active:
            return Color(hex: "#14796D")
        case .completed:
            return .hatchGreenDeep
        }
    }
}

enum BatchLifecycleError: LocalizedError {
    case invalidTransition(from: BatchStatus, to: BatchStatus)
    case notPermitted(role: HatcheryRole, action: String)
    case planNotFound
    case invalidInput(String)
    case signatureFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidTransition(let from, let to):
            return "A \(from.displayName.lowercased()) batch cannot move to \(to.displayName.lowercased())."
        case .notPermitted(let role, let action):
            return "\(role.shortTitle)s are not permitted to \(action)."
        case .planNotFound:
            return "This batch could not be found. It may have been removed on another device."
        case .invalidInput(let message):
            return message
        case .signatureFailed(let message):
            return message
        }
    }
}

// MARK: - Hatchery Sites

/// A Prima production site. Coordinates are approximate town centres used
/// for the manager's geospatial review.
struct HatcherySite: Identifiable, Hashable {
    let id: String
    let name: String
    let sector: String
    let latitude: Double
    let longitude: Double
    /// Maximum eggs the site's setters can hold in a single set.
    let setterCapacity: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static let all: [HatcherySite] = [
        HatcherySite(id: "meegoda", name: "Meegoda Prima Farm", sector: "Hatchery Main Sector", latitude: 6.8436, longitude: 80.0473, setterCapacity: 60_000),
        HatcherySite(id: "kosgama", name: "Kosgama Prima Farm", sector: "GP Breeder Sector", latitude: 6.9333, longitude: 80.1500, setterCapacity: 45_000),
        HatcherySite(id: "halwatura", name: "Halwatura Prima Farm", sector: "Broiler Supply Sector", latitude: 6.7167, longitude: 80.1167, setterCapacity: 30_000)
    ]

    static func site(withID id: String) -> HatcherySite {
        all.first { $0.id == id } ?? all[0]
    }
}

// MARK: - Hatch Plan Record

/// A hatch batch through its whole lifecycle. Persisted in Core Data and
/// mirrored to the Firestore `hatchPlans` collection.
struct HatchPlanRecord: Identifiable, Hashable {
    var id: String
    var batchID: String
    var breed: PoultryBreed
    var flockID: String
    var flockAgeWeeks: Int
    var siteID: String
    var targetChicks: Int
    var safetyBuffer: Double
    var standardHatchability: Double
    var requiredEggs: Int
    var setterTrays: Int
    var plannedSetDate: Date
    var status: BatchStatus
    var createdBy: String
    var createdByUID: String?
    var createdAt: Date
    var updatedAt: Date
    var submittedAt: Date?
    var reviewedBy: String?
    var reviewedAt: Date?
    var approvalSignature: String?
    var rejectionReason: String?
    var certificateText: String?
    var certificateImage: Data?
    var ocrConfidence: Double?
    var executedAt: Date?
    var calendarEventIDs: [String] = []
    var actualChicks: Int?
    var closedAt: Date?
    var closingNotes: String?

    /// Builds a draft from the calculation engine's output.
    init(id: String = UUID().uuidString,
         batchID: String,
         breed: PoultryBreed,
         flockID: String,
         flockAgeWeeks: Int,
         siteID: String,
         plannedSetDate: Date,
         calculation: ProductionCalculation,
         createdBy: String,
         createdByUID: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.batchID = batchID
        self.breed = breed
        self.flockID = flockID
        self.flockAgeWeeks = flockAgeWeeks
        self.siteID = siteID
        self.targetChicks = calculation.targetChicks
        self.safetyBuffer = calculation.safetyBuffer
        self.standardHatchability = calculation.standardHatchability
        self.requiredEggs = calculation.requiredEggs
        self.setterTrays = calculation.setterTrays
        self.plannedSetDate = plannedSetDate
        self.status = .draft
        self.createdBy = createdBy
        self.createdByUID = createdByUID
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    var site: HatcherySite { HatcherySite.site(withID: siteID) }
    var location: String { site.name }

    /// The day eggs went (or will go) into the setters.
    var setDate: Date { executedAt ?? plannedSetDate }
    var transferDate: Date { ProductionCalculator.transferDate(from: setDate) }
    var hatchDateValue: Date { ProductionCalculator.hatchDate(from: setDate) }

    var eggSetDate: String { setDate.formatted(date: .abbreviated, time: .omitted) }
    var hatchDate: String { hatchDateValue.formatted(date: .abbreviated, time: .omitted) }

    /// Expected chicks if the flock hatches at the breed standard.
    var expectedChicks: Int { Int((Double(requiredEggs) * standardHatchability).rounded()) }

    /// Actual hatch of eggs set, available once the batch is closed.
    var actualHatchability: Double? {
        guard let actualChicks, requiredEggs > 0 else { return nil }
        return Double(actualChicks) / Double(requiredEggs)
    }

    /// Chicks delivered against the order target (positive means surplus).
    var chickVariance: Int? {
        actualChicks.map { $0 - targetChicks }
    }

    /// Percentage points above or below the breed standard.
    var hatchabilityVariance: Double? {
        actualHatchability.map { $0 - standardHatchability }
    }

    /// Incubation day 0...21 for an active batch.
    func incubationDay(asOf now: Date = Date()) -> Int {
        guard let executedAt else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: executedAt), to: Calendar.current.startOfDay(for: now)).day ?? 0
        return min(max(days, 0), ProductionCalculator.incubationDays)
    }

    func incubationProgress(asOf now: Date = Date()) -> Double {
        Double(incubationDay(asOf: now)) / Double(ProductionCalculator.incubationDays)
    }

    func daysUntilHatch(asOf now: Date = Date()) -> Int {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: hatchDateValue)).day ?? 0
        return max(days, 0)
    }

    var calculation: ProductionCalculation {
        ProductionCalculation(
            targetChicks: targetChicks,
            safetyBuffer: safetyBuffer,
            standardHatchability: standardHatchability,
            requiredEggs: requiredEggs,
            setterTrays: setterTrays
        )
    }
}
