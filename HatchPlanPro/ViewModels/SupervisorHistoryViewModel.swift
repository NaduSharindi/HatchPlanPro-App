import Foundation
import Combine

struct BatchHistoryItem: Identifiable {
    let id: String
    let planID: String
    let date: String
    let site: String
    let rate: String
    /// Below the age-adjusted breed standard.
    let isBelowStandard: Bool
}

struct BatchHistoryMonth: Identifiable {
    let id: String
    let title: String
    let batches: [BatchHistoryItem]
}

/// Completed-batch history, shared by the supervisor History tab and the
/// manager's Completed Batches screen.
class SupervisorHistoryViewModel: ObservableObject {
    @Published var averageHatchRate: Double = 0
    @Published var totalBatches: Int = 0
    @Published var monthlyHistory: [BatchHistoryMonth] = []

    func loadData(from session: AppSessionViewModel) {
        // Quarterly summary: closed batches from the last 90 days.
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? .distantPast
        let completed = session.completedPlans
        let quarter = completed.filter { ($0.closedAt ?? .distantPast) >= cutoff }
        let rates = quarter.compactMap(\.actualHatchability)

        totalBatches = quarter.count
        averageHatchRate = rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count)

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: completed) { plan -> Date in
            let closed = plan.closedAt ?? plan.updatedAt
            return calendar.date(from: calendar.dateComponents([.year, .month], from: closed)) ?? closed
        }

        monthlyHistory = grouped.keys.sorted(by: >).map { month in
            let items = grouped[month, default: []].map { plan in
                BatchHistoryItem(
                    id: plan.batchID,
                    planID: plan.id,
                    date: "Completed \((plan.closedAt ?? plan.updatedAt).formatted(date: .abbreviated, time: .omitted))",
                    site: plan.site.name,
                    rate: (plan.actualHatchability ?? 0).formatted(.percent.precision(.fractionLength(1))),
                    isBelowStandard: (plan.hatchabilityVariance ?? 0) < 0
                )
            }
            return BatchHistoryMonth(id: month.ISO8601Format(),
                                     title: month.formatted(.dateTime.month(.wide).year()).uppercased(),
                                     batches: items)
        }
    }
}
