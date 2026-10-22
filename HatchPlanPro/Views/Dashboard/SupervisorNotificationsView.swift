import SwiftUI

struct SupervisorNotificationsView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel = SupervisorNotificationsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications")
                                .font(.title2.bold())
                                .foregroundColor(.hatchGreen)
                                .accessibilityAddTraits(.isHeader)

                            if viewModel.unreadCount > 0 {
                                Text("\(viewModel.unreadCount) new")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.hatchOrange)
                            }
                        }
                        Spacer()
                        NavigationLink(destination: SupervisorProfileView()) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundColor(.hatchGreen)
                        }
                        .accessibilityLabel("Profile")
                    }
                    .padding(.horizontal, 20)

                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading notifications...")
                                .tint(.hatchGreen)
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    }

                    ForEach(viewModel.sections) { section in
                        notificationSection(title: section.title, notifications: section.notifications)
                    }

                    if !viewModel.isLoading && viewModel.sections.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bell.slash.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("No notifications yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("You'll be notified about batch alerts, approvals, and hatch updates.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        .accessibilityElement(children: .combine)
                    }

                    Spacer(minLength: 20)
                }
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await refreshNotifications()
            }
            .onAppear {
                viewModel.loadData(from: session)
            }
            .onReceive(session.$supervisorNotifications) { notifications in
                viewModel.buildSections(from: notifications)
                viewModel.unreadCount = session.unreadSupervisorNotifCount
            }
        }
    }

    @MainActor
    private func refreshNotifications() async {
        await withCheckedContinuation { continuation in
            session.loadSupervisorNotifications {
                continuation.resume()
            }
        }
        viewModel.buildSections(from: session.supervisorNotifications)
        viewModel.unreadCount = session.unreadSupervisorNotifCount
    }

    private func notificationSection(
        title: String,
        notifications: [NotificationSectionItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.bold))
                .kerning(1)
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                ForEach(notifications) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.title3)
                            .foregroundColor(item.type == "CRITICAL ALERT" ? .white : .hatchGreen)
                            .padding(10)
                            .background(Circle().fill(item.iconBg))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.type)
                                .font(.caption.weight(.bold))
                                .kerning(0.8)
                                .foregroundColor(item.type == "CRITICAL ALERT" ? Color(hex: "#FFA500") : .hatchGreen)

                            Text(item.title)
                                .font(.caption)
                                .foregroundColor(.hatchGreen)
                                .lineLimit(3)
                        }

                        Spacer()

                        Text(item.time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.type): \(item.title). \(item.time)")
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(hex: "#FAFAFA")))
        .padding(.horizontal, 16)
    }
}
