import Foundation
import Combine

struct BatchHistoryItem: Identifiable {
    let id: String
    let date: String
    let rate: String
}

struct BatchHistoryMonth: Identifiable {
    let id = UUID()
    let title: String
    let batches: [BatchHistoryItem]
}

class SupervisorHistoryViewModel: ObservableObject {
    @Published var averageHatchRate: Double = 0.924
    @Published var totalBatches: Int = 142
    @Published var monthlyHistory: [BatchHistoryMonth] = []
    
    func loadData(from session: AppSessionViewModel) {
        // Mock data loading based on requirements
        self.monthlyHistory = [
            BatchHistoryMonth(title: "OCTOBER 2023", batches: [
                BatchHistoryItem(id: "#B2023-10-A", date: "Completed Oct 28, 2023", rate: "94.5%"),
                BatchHistoryItem(id: "#B2023-10-B", date: "Completed Oct 24, 2023", rate: "91.2%"),
                BatchHistoryItem(id: "#B2023-10-C", date: "Completed Oct 19, 2023", rate: "88.4%")
            ]),
            BatchHistoryMonth(title: "SEPTEMBER 2023", batches: [
                BatchHistoryItem(id: "#B2023-09-E", date: "Completed Sep 30, 2023", rate: "93.8%"),
                BatchHistoryItem(id: "#B2023-09-D", date: "Completed Sep 22, 2023", rate: "95.1%")
            ])
        ]
    }
}
