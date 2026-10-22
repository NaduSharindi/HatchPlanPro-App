//
//  ManagerNotificationsView.swift
//  HatchPlanPro
//
//  Manager notifications screen — displays alerts, approvals,
//  system messages, and weekly reports grouped by time period.
//  Data is fetched from Firebase with Core Data caching.
//

import SwiftUI

/// Full-screen notifications view for the Manager role.
/// Matches the Supervisor notifications layout but uses the
/// Manager colour palette (hatchGreen + hatchOrange accents).
struct ManagerNotificationsView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel = ManagerNotificationsViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header
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
                    NavigationLink(destination: ManagerAccountDetailsView()) {
                        Image(systemName: "bell.badge.fill")
                            .font(.title2)
                            .foregroundColor(.hatchGreen)
                    }
                }
                .padding(.horizontal, 20)

                // MARK: - Loading State
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading notifications...")
                            .tint(.hatchGreen)
                        Spacer()
                    }
                    .padding(.vertical, 40)
                }

                // MARK: - Notification Sections
                ForEach(viewModel.sections) { section in
                    notificationSection(title: section.title, notifications: section.notifications)
                }
                
                // MARK: - Empty State
                if !viewModel.isLoading && viewModel.sections.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("No notifications yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("You'll be notified about batch alerts, approvals, and system updates.")
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
        .onAppear {
            viewModel.loadData(from: session)
        }
    }

    // MARK: - Section Builder

    private func notificationSection(
        title: String,
        notifications: [ManagerNotificationItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.bold))
                .kerning(1)
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                ForEach(notifications) { item in
                    HStack(alignment: .top, spacing: 12) {
                        // Icon badge
                        Image(systemName: item.icon)
                            .font(.title3)
                            .foregroundColor(item.type == "CRITICAL ALERT" ? .white : .white)
                            .padding(10)
                            .background(Circle().fill(item.iconBg))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 6) {
                            // Notification type label
                            Text(item.type)
                                .font(.caption.weight(.bold))
                                .kerning(0.8)
                                .foregroundColor(item.type == "CRITICAL ALERT" ? Color(hex: "#FFA500") : .hatchGreen)

                            // Notification body
                            Text(item.title)
                                .font(.caption)
                                .foregroundColor(.hatchGreen)
                                .lineLimit(3)
                        }

                        Spacer()

                        // Timestamp
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

#Preview {
    ManagerNotificationsView()
        .environmentObject(AppSessionViewModel())
}
