import Foundation
import Combine
import SwiftUI

/// ViewModel for the Manager Alerts screen.
/// Loads alerts from session data (Firebase-backed) and provides
/// filtering and badge count functionality.
class ManagerAlertsViewModel: ObservableObject {
    @Published var alerts: [HatcheryAlert] = []
    @Published var isLoading: Bool = false
    @Published var unreadCount: Int = 0
    
    /// Loads alert data from the session and syncs with Core Data.
    func loadData(from session: AppSessionViewModel) {
        isLoading = true
        self.alerts = session.alerts
        self.unreadCount = alerts.count
        
        // Cache alerts to Core Data for offline access
        for alert in alerts {
            CoreDataManager.shared.saveNotification(
                id: UUID().uuidString,
                type: alert.severity,
                title: alert.title,
                message: alert.details,
                timestamp: Date(),
                timeLabel: alert.timeLabel,
                isRead: false,
                role: "manager"
            )
        }
        
        isLoading = false
    }
}
