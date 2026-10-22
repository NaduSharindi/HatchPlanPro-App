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
}

class SupervisorBatchesViewModel: ObservableObject {
    @Published var approvedBatches: [SupervisorBatchInsight] = []
    @Published var pendingBatches: [SupervisorBatchInsight] = []
    @Published var rejectedBatches: [SupervisorBatchInsight] = []
    @Published var syncedBatches: [SupervisorBatchInsight] = []
    
    @Published var efficiencyIncrease: Double = 4.2
    @Published var reviewMessage: String = "Reviews by Manager Sarah & Ops Lead Mike"
    
    func loadData(from session: AppSessionViewModel) {
        let plans = session.hatchPlans

        approvedBatches = plans.filter { $0.status == .approvedReady || $0.status == .synced }.map {
            SupervisorBatchInsight(id: $0.batchID, batchID: $0.batchID, breed: $0.breed, date: $0.eggSetDate, status: $0.status.displayName, statusCode: $0.status, statusColor: $0.status.color, targetChicks: $0.targetChicks)
        }

        pendingBatches = plans.filter { $0.status == .pendingReview }.map {
            SupervisorBatchInsight(id: $0.batchID, batchID: $0.batchID, breed: $0.breed, date: $0.eggSetDate, status: $0.status.displayName, statusCode: $0.status, statusColor: $0.status.color, targetChicks: $0.targetChicks)
        }

        rejectedBatches = plans.filter { $0.status == .rejected }.map {
            SupervisorBatchInsight(id: $0.batchID, batchID: $0.batchID, breed: $0.breed, date: $0.eggSetDate, status: $0.status.displayName, statusCode: $0.status, statusColor: $0.status.color, targetChicks: $0.targetChicks)
        }

        syncedBatches = plans.filter { $0.status == .synced }.map {
            SupervisorBatchInsight(id: $0.batchID, batchID: $0.batchID, breed: $0.breed, date: $0.eggSetDate, status: $0.status.displayName, statusCode: $0.status, statusColor: $0.status.color, targetChicks: $0.targetChicks)
        }
    }
}
