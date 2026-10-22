import Foundation
import Combine
import SwiftUI

struct NotificationSectionItem: Identifiable {
    let id = UUID()
    let type: String
    let icon: String
    let iconBg: Color
    let title: String
    let time: String
}

struct NotificationSection: Identifiable {
    let id = UUID()
    let title: String
    let notifications: [NotificationSectionItem]
}

class SupervisorNotificationsViewModel: ObservableObject {
    @Published var sections: [NotificationSection] = []
    @Published var isLoading = false
    @Published var unreadCount = 0

    func loadData(from session: AppSessionViewModel) {
        isLoading = true
        session.loadSupervisorNotifications { [weak self] in
            guard let self else { return }
            self.buildSections(from: session.supervisorNotifications)
            self.unreadCount = session.unreadSupervisorNotifCount
            self.isLoading = false
        }
    }

    func refresh(from session: AppSessionViewModel) {
        loadData(from: session)
    }

    func buildSections(from notifications: [HatcheryNotification]) {
        guard !notifications.isEmpty else {
            sections = []
            unreadCount = 0
            return
        }

        let grouped = Dictionary(grouping: notifications) { notification in
            let hoursSince = Date().timeIntervalSince(notification.timestamp) / 3600
            if hoursSince < 24 {
                return "TODAY"
            } else if hoursSince < 168 {
                return "LAST WEEK"
            } else {
                return "EARLIER"
            }
        }

        sections = ["TODAY", "LAST WEEK", "EARLIER"].compactMap { key in
            guard let items = grouped[key], !items.isEmpty else { return nil }
            return NotificationSection(title: key, notifications: items.map { notification in
                NotificationSectionItem(
                    type: notification.type.displayName,
                    icon: notification.type.iconName,
                    iconBg: notification.type == .criticalAlert ? Color(hex: "#FFA500") : (notification.type == .approvalUpdate ? .hatchGreen : Color(hex: "#A0A0A0")),
                    title: notification.title,
                    time: notification.timeLabel
                )
            })
        }

        unreadCount = notifications.count
    }
}
