import Foundation
import Combine
import SwiftUI

struct HatchabilityPoint: Identifiable {
    let id: String
    let batchID: String
    let closedAt: Date
    let series: String
    let value: Double
}

class ManagerDashboardViewModel: ObservableObject {
    static let rollingWindowDays = 30

    @Published var fullName: String = ""
    @Published var chartPoints: [HatchabilityPoint] = []
    @Published var averageActual: Double?
    @Published var averageVariance: Double?
    @Published var chicksDelivered = 0
    @Published var batchesClosed = 0
    @Published var pendingCount = 0
    @Published var activeCount = 0
    @Published var eggsIncubating = 0
    @Published var nextHatch: HatchPlanRecord?

    func loadData(from session: AppSessionViewModel) {
        fullName = session.currentUser.fullName
        pendingCount = session.pendingPlans.count
        activeCount = session.activePlans.count
        eggsIncubating = session.activePlans.reduce(0) { $0 + $1.requiredEggs }
        nextHatch = session.activePlans.first

        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.rollingWindowDays, to: Date()) ?? .distantPast
        let window = session.completedPlans
            .filter { ($0.closedAt ?? .distantPast) >= cutoff }
            .sorted { ($0.closedAt ?? .distantPast) < ($1.closedAt ?? .distantPast) }

        chartPoints = window.flatMap { plan -> [HatchabilityPoint] in
            guard let actual = plan.actualHatchability, let closed = plan.closedAt else { return [] }
            return [
                HatchabilityPoint(id: plan.id + "-std", batchID: plan.batchID, closedAt: closed, series: "Standard", value: plan.standardHatchability),
                HatchabilityPoint(id: plan.id + "-act", batchID: plan.batchID, closedAt: closed, series: "Actual", value: actual)
            ]
        }

        let actuals = window.compactMap(\.actualHatchability)
        let variances = window.compactMap(\.hatchabilityVariance)
        averageActual = actuals.isEmpty ? nil : actuals.reduce(0, +) / Double(actuals.count)
        averageVariance = variances.isEmpty ? nil : variances.reduce(0, +) / Double(variances.count)
        chicksDelivered = window.compactMap(\.actualChicks).reduce(0, +)
        batchesClosed = window.count
    }
}
