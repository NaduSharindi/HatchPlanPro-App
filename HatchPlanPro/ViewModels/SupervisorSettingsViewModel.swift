import Foundation
import Combine
import SwiftUI

class SupervisorSettingsViewModel: ObservableObject {
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("hapticEnabled") var hapticEnabled: Bool = true
    @AppStorage("siriEnabled") var siriEnabled: Bool = true
    
    @Published var roleTitle: String = "Supervisor"
    @Published var email: String = "lead.agronomist@hatchplan.pro"
    
    func loadData(from session: AppSessionViewModel) {
        self.roleTitle = session.currentRole.rawValue
        self.email = session.currentUser.email
    }
}
