//
//  NotificationsView.swift
//  HatchPlanPro
//
//  Role-aware activity feed built from the batch lifecycle.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var openPlanID: String?
    @State private var reviewPlanID: String?

    private var sections: [(title: String, items: [ActivityItem])] {
        let calendar = Calendar.current
        let now = Date()
        var today: [ActivityItem] = [], week: [ActivityItem] = [], earlier: [ActivityItem] = []
        for item in session.activityItems {
            if calendar.isDateInToday(item.date) {
                today.append(item)
            } else if now.timeIntervalSince(item.date) < 7 * 86_400 {
                week.append(item)
            } else {
                earlier.append(item)
            }
        }
        return [("TODAY", today), ("THIS WEEK", week), ("EARLIER", earlier)].filter { !$0.items.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(title: "Notifications", showsBack: false) {
                    if session.unreadActivityCount > 0 {
                        Button("Mark all read") { session.markAllActivityRead() }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.hatchGreen)
                    }
                }

                if session.unreadActivityCount > 0 {
                    Text("\(session.unreadActivityCount) new")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.hatchOrange)
                        .padding(.horizontal, 20)
                }

                if sections.isEmpty {
                    ContentUnavailableView("No notifications yet", systemImage: "bell.slash",
                                           description: Text("Approvals, incubation milestones and hatch results will appear here."))
                        .padding(.top, 60)
                }

                ForEach(sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.caption.weight(.bold))
                            .kerning(1.2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            ForEach(section.items) { item in
                                row(item)
                                if item.id != section.items.last?.id {
                                    Divider().padding(.leading, 76)
                                }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $openPlanID) { BatchDetailView(planID: $0) }
        .navigationDestination(item: $reviewPlanID) { ManagerApprovalPlanView(planID: $0) }
    }

    private func row(_ item: ActivityItem) -> some View {
        Button(action: { open(item) }) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: item.kind.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(item.kind.tint)
                    .frame(width: 46, height: 46)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(item.kind.tint.opacity(0.14)))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.kind.label)
                            .font(.caption.weight(.bold))
                            .kerning(0.8)
                            .foregroundColor(item.kind.tint)
                        Spacer()
                        Text(item.date, format: .relative(presentation: .named))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Text(item.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)

                    if item.needsAction && item.kind == .submitted && session.currentRole == .manager {
                        HStack(spacing: 10) {
                            Text("Review Now")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.hatchGreenDeep))
                            if !item.isRead {
                                Button("Dismiss") { session.markActivityRead(item.id) }
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color.gray.opacity(0.15)))
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                if !item.isRead {
                    Circle().fill(Color.hatchOrange).frame(width: 8, height: 8).padding(.top, 6)
                }
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(item.isRead ? "Opens the batch" : "Unread. Opens the batch")
    }

    private func open(_ item: ActivityItem) {
        session.markActivityRead(item.id)
        if item.kind == .submitted && session.currentRole == .manager && session.plan(withID: item.planID)?.status == .pendingReview {
            reviewPlanID = item.planID
        } else {
            openPlanID = item.planID
        }
    }
}
