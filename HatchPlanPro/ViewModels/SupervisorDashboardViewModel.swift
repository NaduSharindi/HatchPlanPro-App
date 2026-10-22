import Foundation
import Combine

class SupervisorDashboardViewModel: ObservableObject {
    @Published var metrics: [HatcheryMetric] = []
    @Published var tasks: [HatcheryTask] = []
    @Published var fullName: String = ""
    @Published var yieldPrediction: Double = 0.82
    
    func loadData(from session: AppSessionViewModel) {
        self.metrics = session.metrics
        self.tasks = session.tasks
        self.fullName = session.currentUser.fullName
    }
}
