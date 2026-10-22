import Foundation
import Combine

class SupervisorScheduleViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var efficiencyForecastTitle: String = ""
    @Published var efficiencyForecastPercentage: Double = 0.0
    private var allBatches: [ScheduledBatch] = []
    
    var groupedSchedules: [(date: String, batches: [ScheduledBatch])] {
        let filtered = searchText.isEmpty ? allBatches : allBatches.filter { batch in
            batch.batchID.localizedCaseInsensitiveContains(searchText) ||
            batch.breed.localizedCaseInsensitiveContains(searchText)
        }
        
        let grouped = Dictionary(grouping: filtered) { $0.dateLabel }
        return grouped.sorted { date1, date2 in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d"
            if let d1 = dateFormatter.date(from: date1.key),
               let d2 = dateFormatter.date(from: date2.key) {
                return d1 < d2
            }
            return date1.key < date2.key
        }.map { (key, value) in
            (date: key, batches: value.sorted { $0.timeOfDay < $1.timeOfDay })
        }
    }
    
    func loadData(from session: AppSessionViewModel) {
        self.allBatches = session.scheduledBatches
        self.efficiencyForecastTitle = session.efficiencyForecast.title
        self.efficiencyForecastPercentage = session.efficiencyForecast.percentage
    }
}
