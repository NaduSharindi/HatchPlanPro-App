import SwiftUI

struct ManagerAlertsView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel = ManagerAlertsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(viewModel.alerts, id: \.title) { alert in
                    AlertCardView(
                        title: alert.title,
                        details: alert.details,
                        severity: alert.severity,
                        timeLabel: alert.timeLabel,
                        iconName: alert.iconName
                    )
                }
            }
            .padding()
        }
        .background(Color.figmaBackground.ignoresSafeArea())
        .onAppear {
            viewModel.loadData(from: session)
        }
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
