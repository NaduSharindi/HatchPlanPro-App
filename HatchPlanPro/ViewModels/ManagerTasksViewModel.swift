import Foundation
import Combine
import SwiftUI

class ManagerTasksViewModel: ObservableObject {
    @Published var tasks: [HatcheryTask] = []
    
    func loadData(from session: AppSessionViewModel) {
        self.tasks = session.tasks
    }
}
