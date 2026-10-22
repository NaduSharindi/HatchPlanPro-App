import Foundation
import Combine
import SwiftUI

class ManagerDashboardViewModel: ObservableObject {
    @Published var metrics: [HatcheryMetric] = []
    @Published var tasks: [HatcheryTask] = []
    @Published var criticalBatches: [HatcheryBatch] = []
    @Published var fullName: String = ""
    @Published var summary: String = ""
    
    func loadData(from session: AppSessionViewModel) {
        self.metrics = session.metrics
        self.tasks = session.tasks
        self.criticalBatches = session.batches.filter { $0.isCritical }
        self.fullName = session.currentUser.fullName
        self.summary = session.todaySummary
    }
}
