import SwiftUI

struct ManagerApprovalsView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    private var pendingItems: [ManagerApprovalItem] {
        session.pendingPlans.map { plan in
            ManagerApprovalItem(plan: plan, isUrgent: true)
        }
    }

    private var approvedItems: [ManagerApprovalItem] {
        session.approvedPlans.map { plan in
            ManagerApprovalItem(plan: plan, isUrgent: false)
        }
    }

    private var rejectedItems: [ManagerApprovalItem] {
        session.rejectedPlans.map { plan in
            ManagerApprovalItem(plan: plan, isUrgent: false)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header

                VStack(alignment: .leading, spacing: 10) {
                    Text("QUEUE")
                        .font(.caption.weight(.bold))
                        .tracking(1.8)
                        .foregroundColor(.hatchOrange)
                    Text("\(pendingItems.count) Pending")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                approvalSection(title: "PENDING QUEUE", items: pendingItems, showActions: true)
                approvalSection(title: "APPROVED LIST", items: approvedItems, showActions: false)
                approvalSection(title: "REJECTED LIST", items: rejectedItems, showActions: false)

                bulkReviewCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func approvalSection(title: String, items: [ManagerApprovalItem], showActions: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(items.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 14) {
                ForEach(items) { item in
                    if showActions, let plan = item.plan {
                        NavigationLink(destination: ManagerApprovalPlanView(plan: plan)) {
                            ApprovalRowView(item: item)
                        }
                        .buttonStyle(.plain)
                    } else {
                        ApprovalRowView(item: item)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "arrow.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.hatchGreen)
                    .frame(width: 42, height: 42)
            }

            Spacer()

            Text("Approvals")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.hatchGreen)

            Spacer()

            Circle()
                .fill(LinearGradient(colors: [.brown.opacity(0.7), .black.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(Text("M").font(.caption.weight(.bold)).foregroundColor(.white))
                .frame(width: 42, height: 42)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    private var bulkReviewCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Bulk Review")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            Text("Accelerate your workflow by processing all verified standard requests.")
                .font(.body)
                .foregroundColor(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: { session.approveAllPendingPlans(reviewedBy: session.currentUser.fullName) }) {
                Text("Start Batch Approval")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.hatchGreenDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.hatchOrangeSoft))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [.hatchGreenDeep, .hatchGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: .hatchGreen.opacity(0.18), radius: 16, x: 0, y: 10)
    }
}

private struct ManagerApprovalItem: Identifiable {
    let id = UUID()
    let name: String
    let batchID: String
    let location: String
    let requestedAt: String
    let chicksNeeded: String
    let avatarSeed: String
    let isUrgent: Bool
    let plan: HatchPlanRecord?

    init(plan: HatchPlanRecord, isUrgent: Bool) {
        self.name = plan.createdBy
        self.batchID = plan.batchID
        self.location = plan.location
        self.requestedAt = plan.createdAt.formatted(date: .abbreviated, time: .shortened)
        self.chicksNeeded = "\(plan.targetChicks.formatted()) chicks needed"
        self.avatarSeed = String(plan.createdBy.prefix(1))
        self.isUrgent = isUrgent
        self.plan = plan
    }
}

private struct ApprovalRowView: View {
    let item: ManagerApprovalItem

    var body: some View {
        HStack(spacing: 14) {
            AvatarBadge(seed: item.avatarSeed, isUrgent: item.isUrgent)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(item.batchID)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.hatchGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.hatchGreenSoft))
                }

                Text("\(item.chicksNeeded), \(item.location)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("REQUESTED \(item.requestedAt.uppercased())")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

private struct AvatarBadge: View {
    let seed: String
    let isUrgent: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(colors: [Color(red: 0.15, green: 0.2, blue: 0.25), Color(red: 0.07, green: 0.1, blue: 0.13)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(width: 52, height: 52)
                .clipShape(Circle())

            Text(seed)
                .font(.headline.weight(.bold))
                .foregroundColor(.white)

            Circle()
                .fill(isUrgent ? Color.hatchOrange : Color.hatchGreen)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(x: 2, y: 2)
        }
    }
}

#Preview {
    NavigationStack {
        ManagerApprovalsView()
            .environmentObject(AppSessionViewModel())
    }
}
