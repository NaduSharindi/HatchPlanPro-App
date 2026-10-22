import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    var body: some View {
        if session.currentRole == .supervisor {
            supervisorDashboard
        } else {
            managerDashboard
        }
    }

    private var supervisorDashboard: some View {
        NavigationStack {
            TabView(selection: $session.selectedTabIndex) {
                SupervisorHomeView()
                    .tabItem {
                        Label("HOME", systemImage: "house.fill")
                    }
                    .tag(0)

                SupervisorBatchesView()
                    .tabItem {
                        Label("BATCHES", systemImage: "tray.full.fill")
                    }
                    .tag(1)

                SupervisorHistoryView()
                    .tabItem {
                        Label("HISTORY", systemImage: "clock.fill")
                    }
                    .tag(2)

                SupervisorNotificationsView()
                    .tabItem {
                        Label("ALERTS", systemImage: "bell.fill")
                    }
                    .tag(3)
                    .badge(session.unreadSupervisorNotifCount)

                SupervisorSettingsView()
                    .tabItem {
                        Label("SETTINGS", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .tint(.hatchGreen)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(Color.white, for: .tabBar)
            .onAppear {
                session.loadSupervisorNotifications()
            }
        }
    }

    private var managerDashboard: some View {
        NavigationStack {
            TabView(selection: $session.selectedTabIndex) {
                ManagerHomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                ManagerApprovalsView()
                    .tabItem {
                        Label("Approvals", systemImage: "checklist")
                    }
                    .tag(1)

                ManagerMapView()
                    .tabItem {
                        Label("Map", systemImage: "map.fill")
                    }
                    .tag(2)

                ManagerNotificationsView()
                    .tabItem {
                        Label("Alerts", systemImage: "bell.fill")
                    }
                    .tag(3)

                ManagerSettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .tint(.hatchGreen)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(Color.white, for: .tabBar)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSessionViewModel())
}
