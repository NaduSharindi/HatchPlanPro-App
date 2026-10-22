//
//  SupervisorHomeView.swift
//  HatchPlanPro
//
//  Supervisor dashboard for the user's site, built from live batch data.
//

import SwiftUI

struct SupervisorHomeView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var showNewPlan = false

    private var site: HatcherySite { session.currentUser.site }
    private var sitePlans: [HatchPlanRecord] { session.hatchPlans.filter { $0.siteID == site.id } }
    private var active: [HatchPlanRecord] { sitePlans.filter { $0.status == .active }.sorted { $0.hatchDateValue < $1.hatchDateValue } }

    private var averageProgress: Double? {
        guard !active.isEmpty else { return nil }
        return active.map { $0.incubationProgress() }.reduce(0, +) / Double(active.count)
    }

    private var chicksThisWeek: Int {
        let cutoff = Date().addingTimeInterval(-7 * 86_400)
        return sitePlans.filter { ($0.closedAt ?? .distantPast) >= cutoff }.compactMap(\.actualChicks).reduce(0, +)
    }

    private var eggsIncubating: Int { active.reduce(0) { $0 + $1.requiredEggs } }

    /// Last 30 days of closed batches at this site vs their breed standard.
    private var velocity: (rate: Double, delta: Double)? {
        let cutoff = Date().addingTimeInterval(-30 * 86_400)
        let closed = sitePlans.filter { ($0.closedAt ?? .distantPast) >= cutoff }
        let rates = closed.compactMap(\.actualHatchability)
        let deltas = closed.compactMap(\.hatchabilityVariance)
        guard !rates.isEmpty else { return nil }
        return (rates.reduce(0, +) / Double(rates.count), deltas.reduce(0, +) / Double(deltas.count))
    }

    private var yieldCoverage: Double? {
        let orders = active.reduce(0) { $0 + $1.targetChicks }
        guard orders > 0 else { return nil }
        return Double(active.reduce(0) { $0 + $1.expectedChicks }) / Double(orders)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case ..<12: return "Good Morning"
        case ..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        productionCard
                        pipelineRow
                        upcomingSection
                        syncCard
                        yieldCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 96)
                }

                Button(action: { showNewPlan = true }) {
                    Label("New Plan", systemImage: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.hatchGreenDeep))
                        .shadow(color: .hatchGreen.opacity(0.35), radius: 12, y: 6)
                }
                .padding(20)
                .accessibilityHint("Starts a new production plan")
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showNewPlan) { ScannerIntroView() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                NavigationLink(destination: ProfileView()) {
                    ProfileAvatar(profile: session.currentUser, size: 38)
                }
                Image(systemName: "leaf").foregroundColor(.hatchGreen)
                Text("HatchPlan Pro").font(.headline.weight(.bold)).foregroundColor(.hatchGreenDeep)
                Spacer()
                Button(action: { session.selectedTabIndex = 3 }) {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundColor(.hatchGreen)
                        .overlay(alignment: .topTrailing) {
                            if session.unreadActivityCount > 0 {
                                Circle().fill(Color.red).frame(width: 9, height: 9).offset(x: 2, y: -2)
                            }
                        }
                }
                .accessibilityLabel("Notifications")
                .accessibilityValue(session.unreadActivityCount > 0 ? "\(session.unreadActivityCount) unread" : "None unread")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(greeting), \(session.currentUser.firstName)")
                    .font(.title2.weight(.bold))
                Text(site.name).font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var productionCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().stroke(Color.hatchOrange.opacity(0.15), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: averageProgress ?? 0)
                    .stroke(Color.hatchOrange, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text("INCUBATION PROGRESS").font(.caption2.weight(.bold)).foregroundColor(.hatchOrange)
                    Text(averageProgress.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "—")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("\(active.count) batch\(active.count == 1 ? "" : "es")").font(.caption).foregroundColor(.secondary)
                }
            }
            .frame(width: 190, height: 190)
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 6) {
                Text("Production Velocity").font(.headline)
                Text(velocityText).font(.subheadline).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                statTile("CHICKS THIS WEEK", chicksThisWeek.formatted(), fill: Color.hatchGreenSoft, ink: .hatchGreenDeep)
                statTile("EGGS INCUBATING", eggsIncubating.formatted(), fill: Color(hex: "#FFF6DA"), ink: Color(hex: "#7A5C00"))
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white))
    }

    private var velocityText: String {
        guard let velocity else {
            return "No batches closed at \(site.name) in the last 30 days. Results appear after you log hatch numbers."
        }
        let rate = velocity.rate.formatted(.percent.precision(.fractionLength(1)))
        let delta = abs(velocity.delta).formatted(.percent.precision(.fractionLength(1)))
        return velocity.delta >= 0
            ? "Hatchability is averaging \(rate), \(delta) above breed standard over the last 30 days."
            : "Hatchability is averaging \(rate), \(delta) below breed standard. Review observations on recent batches."
    }

    private func statTile(_ title: String, _ value: String, fill: Color, ink: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2.weight(.bold)).foregroundColor(ink.opacity(0.8))
            Text(value).font(.title2.weight(.bold)).foregroundColor(ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(fill))
        .accessibilityElement(children: .combine)
    }

    private var pipelineRow: some View {
        HStack(spacing: 10) {
            pipelineChip("Pending", count: sitePlans.filter { $0.status == .pendingReview }.count, color: Color(hex: "#FFA500"))
            pipelineChip("Ready", count: sitePlans.filter { $0.status == .approvedReady }.count, color: .hatchGreen)
            pipelineChip("Rejected", count: sitePlans.filter { $0.status == .rejected }.count, color: Color(hex: "#FF6B6B"))
        }
    }

    private func pipelineChip(_ title: String, count: Int, color: Color) -> some View {
        Button(action: { session.selectedTabIndex = 1 }) {
            VStack(spacing: 4) {
                Text("\(count)").font(.title3.weight(.bold)).foregroundColor(color)
                Text(title.uppercased()).font(.caption2.weight(.bold)).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(count) \(title) plans")
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Milestones").font(.headline)
                Spacer()
                NavigationLink("View Schedule", destination: ScheduleView())
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.hatchGreen)
            }

            if session.scheduledBatches.isEmpty {
                Text("No approved or incubating batches yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.white))
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                    ForEach(session.scheduledBatches.prefix(4)) { batch in
                        NavigationLink(destination: BatchDetailView(planID: batch.id)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: batch.status == "CRITICAL" ? "exclamationmark.triangle.fill" : "calendar")
                                        .foregroundColor(batch.status == "CRITICAL" ? .hatchOrange : .hatchGreen)
                                    Spacer()
                                    if !batch.status.isEmpty {
                                        Text(batch.status).font(.caption2.weight(.bold)).foregroundColor(.hatchOrange)
                                    }
                                }
                                Text(batch.dateLabel.components(separatedBy: ",").first ?? "")
                                    .font(.caption2.weight(.bold)).foregroundColor(.secondary)
                                Text("\(batch.time) \(batch.timeOfDay)").font(.headline)
                                Text("Batch \(batch.batchID)").font(.caption).foregroundColor(.secondary)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var syncCard: some View {
        let pending = session.pendingSyncCount
        return HStack(spacing: 14) {
            Image(systemName: pending == 0 ? "checkmark.icloud.fill" : "icloud.and.arrow.up.fill")
                .font(.title2)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 4) {
                Text("Cloud Sync").font(.headline).foregroundColor(.white)
                Text(pending == 0
                     ? "All batches are synced with the operations manager."
                     : "\(pending) change\(pending == 1 ? "" : "s") saved on this device, uploading when online.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(LinearGradient(colors: [.hatchGreenDeep, .hatchGreen], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .accessibilityElement(children: .combine)
    }

    private var yieldCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Yield Projection", systemImage: "chart.bar.fill").font(.headline)
            if let coverage = yieldCoverage {
                ProgressView(value: min(coverage, 1)).tint(.hatchOrange)
                HStack {
                    Text("PROJECTED CHICKS VS ORDERS").font(.caption2.weight(.bold)).foregroundColor(.secondary)
                    Spacer()
                    Text(coverage.formatted(.percent.precision(.fractionLength(0))))
                        .font(.caption.weight(.bold)).foregroundColor(.hatchGreen)
                }
            } else {
                Text("Set an approved batch to see its projected yield.")
                    .font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color(hex: "#ECEDF1")))
    }
}
