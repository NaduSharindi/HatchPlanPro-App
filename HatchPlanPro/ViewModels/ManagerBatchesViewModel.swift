import Foundation
import Combine
import SwiftUI

class ManagerBatchesViewModel: ObservableObject {
    @Published var batches: [HatcheryBatch] = []
    
    func loadData(from session: AppSessionViewModel) {
        self.batches = session.batches
    }
}
