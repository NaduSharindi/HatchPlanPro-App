import SwiftUI
import CoreSpotlight

extension Notification.Name {
    /// Posted with `object: planID` when a notification or Spotlight result opens a batch.
    static let openHatchPlan = Notification.Name("hatchplan.openPlan")
}

/// Role-based root. Each tab owns exactly one NavigationStack.
struct ContentView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    var body: some View {
        Group {
            if session.currentRole == .supervisor {
                supervisorDashboard
            } else {
                managerDashboard
            }
        }
        .tint(.hatchGreen)
        .sheet(item: Binding(get: { session.deepLinkPlanID.map(DeepLink.init) },
                             set: { session.deepLinkPlanID = $0?.id })) { link in
            NavigationStack { BatchDetailView(planID: link.id) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHatchPlan)) { note in
            if let planID = note.object as? String { session.deepLinkPlanID = planID }
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            if let planID = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                session.deepLinkPlanID = planID
            }
        }
    }

    private var supervisorDashboard: some View {
        TabView(selection: $session.selectedTabIndex) {
            SupervisorHomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            SupervisorBatchesView()
                .tabItem { Label("Batches", systemImage: "tray.full.fill") }
                .tag(1)

            SupervisorHistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(2)

            NavigationStack { NotificationsView() }
                .tabItem { Label("Alerts", systemImage: "bell.fill") }
                .tag(3)
                .badge(session.unreadActivityCount)

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
    }

    private var managerDashboard: some View {
        TabView(selection: $session.selectedTabIndex) {
            NavigationStack { ManagerHomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            NavigationStack { ManagerApprovalsView() }
                .tabItem { Label("Approvals", systemImage: "checklist") }
                .tag(1)
                .badge(session.pendingPlans.count)

            NavigationStack { ManagerMapView() }
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(2)

            NavigationStack { NotificationsView() }
                .tabItem { Label("Alerts", systemImage: "bell.fill") }
                .tag(3)
                .badge(session.unreadActivityCount)

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
    }
}

private struct DeepLink: Identifiable {
    let id: String
}

#Preview {
    ContentView()
        .environmentObject(AppSessionViewModel())
}
