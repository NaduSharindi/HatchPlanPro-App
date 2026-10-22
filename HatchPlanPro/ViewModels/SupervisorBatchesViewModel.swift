import Foundation
import Combine
import SwiftUI

struct SupervisorBatchInsight: Identifiable {
    let id: String
    let batchID: String
    let breed: String
    let date: String
    let status: String
    let statusCode: BatchStatus
    let statusColor: Color
    let targetChicks: Int
    let rejectionReason: String?

    init(plan: HatchPlanRecord) {
        id = plan.id
        batchID = plan.batchID
        breed = plan.breed.rawValue
        date = plan.status == .active ? "Day \(plan.incubationDay()) • hatch \(plan.hatchDate)" : "Set \(plan.eggSetDate)"
        status = plan.status.displayName
        statusCode = plan.status
        statusColor = plan.status.color
        targetChicks = plan.targetChicks
        rejectionReason = plan.rejectionReason
    }
}

class SupervisorBatchesViewModel: ObservableObject {
    @Published var approvedBatches: [SupervisorBatchInsight] = []
    @Published var pendingBatches: [SupervisorBatchInsight] = []
    @Published var rejectedBatches: [SupervisorBatchInsight] = []
    /// Batches that have been set and are synced to the incubation calendar.
    @Published var syncedBatches: [SupervisorBatchInsight] = []

    @Published var efficiencyIncrease: Double = 0
    @Published var reviewMessage: String = ""

    func loadData(from session: AppSessionViewModel) {
        approvedBatches = session.approvedPlans.map { SupervisorBatchInsight(plan: $0) }
        pendingBatches = session.pendingPlans.map { SupervisorBatchInsight(plan: $0) }
        rejectedBatches = session.rejectedPlans.map { SupervisorBatchInsight(plan: $0) }
        syncedBatches = session.activePlans.map { SupervisorBatchInsight(plan: $0) }

        // Compare the last 7 days of closed batches with the 7 before them.
        let now = Date()
        func average(_ range: ClosedRange<Double>) -> Double? {
            let rates = session.completedPlans.compactMap { plan -> Double? in
                guard let closed = plan.closedAt else { return nil }
                let age = now.timeIntervalSince(closed) / 86_400
                return range.contains(age) ? plan.actualHatchability : nil
            }
            return rates.isEmpty ? nil : rates.reduce(0, +) / Double(rates.count)
        }
        if let recent = average(0...7), let previous = average(7.001...14) {
            efficiencyIncrease = (recent - previous) * 100
        } else {
            efficiencyIncrease = 0
        }

        let reviewers = Set(session.hatchPlans.compactMap(\.reviewedBy)).sorted()
        reviewMessage = reviewers.isEmpty ? "No manager reviews yet" : "Reviews by \(reviewers.joined(separator: " & "))"
    }
}
