import SwiftUI
import Charts

struct ManagerHomeView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel = ManagerDashboardViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                analyticsCard
                statusCards
                statsGrid
                yieldCard
                productionStatusCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarHidden(true)
        .onReceive(session.$hatchPlans) { _ in
            viewModel.loadData(from: session)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 12) {
                AppLogoView(size: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(greeting), \(viewModel.fullName)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.hatchGreen)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("All Prima sites • \(syncLabel)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: { session.selectedTabIndex = 3 }) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.hatchGreen)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white))
                    .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
            }
            .accessibilityLabel("Notifications")
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case ..<12: return "Morning"
        case ..<17: return "Afternoon"
        default: return "Evening"
        }
    }

    private var syncLabel: String {
        session.pendingSyncCount == 0 ? "Synced" : "\(session.pendingSyncCount) awaiting sync"
    }

    // MARK: - Charts

    private var analyticsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("COMPARATIVE ANALYTICS")
                        .font(.caption.weight(.bold))
                        .tracking(1.8)
                        .foregroundColor(.hatchOrange)
                    Text("Hatchability Performance")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.hatchGreen)
                    Text("Closed batches, last \(ManagerDashboardViewModel.rollingWindowDays) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            if viewModel.chartPoints.isEmpty {
                ContentUnavailableView("No Closed Batches", systemImage: "chart.bar",
                                       description: Text("Results appear once supervisors log hatch numbers."))
                    .frame(height: 200)
            } else {
                Chart(viewModel.chartPoints) { point in
                    // Bars start at the axis floor so they stay inside the plot.
                    BarMark(
                        x: .value("Batch", point.batchID.replacingOccurrences(of: "#B", with: "")),
                        yStart: .value("Floor", 0.6),
                        yEnd: .value("Hatchability", max(point.value, 0.6))
                    )
                    .foregroundStyle(by: .value("Series", point.series))
                    .position(by: .value("Series", point.series))
                    .cornerRadius(4)
                }
                .chartForegroundStyleScale(["Standard": Color.hatchGreen, "Actual": Color.hatchOrange])
                .chartYScale(domain: 0.6...1.0)
                .chartYAxis {
                    AxisMarks(values: [0.6, 0.7, 0.8, 0.9, 1.0]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let number = value.as(Double.self) {
                                Text(number.formatted(.percent.precision(.fractionLength(0))))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.caption2)
                    }
                }
                .chartLegend(position: .top, alignment: .trailing)
                .frame(height: 210)
                .accessibilityLabel("Standard versus actual hatchability for \(viewModel.batchesClosed) closed batches")
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 8)
    }

    private var statusCards: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: ManagerScheduleView()) {
                navigationSummaryCard(title: "Ongoing Hatches", subtitle: "\(viewModel.activeCount) incubating", icon: "circle.grid.2x2.fill")
            }
            .buttonStyle(.plain)

            NavigationLink(destination: ManagerBatchHistoryListView()) {
                navigationSummaryCard(title: "Completed Batches", subtitle: "Performance history", icon: "tray.full.fill")
            }
            .buttonStyle(.plain)
        }
    }

    private func navigationSummaryCard(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.hatchGreenSoft)
                Image(systemName: icon)
                    .foregroundColor(.hatchGreen)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.hatchGreen)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(0.7))
                .font(.caption.weight(.semibold))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private var statsGrid: some View {
        VStack(spacing: 14) {
            statCard("AVG HATCHABILITY (\(ManagerDashboardViewModel.rollingWindowDays)D)",
                     value: viewModel.averageActual.map { $0.formatted(.percent.precision(.fractionLength(1))) } ?? "—",
                     detail: viewModel.averageVariance.map { "\($0 >= 0 ? "+" : "")\($0.formatted(.percent.precision(.fractionLength(1)))) vs standard" } ?? "No data",
                     detailColor: (viewModel.averageVariance ?? 0) >= 0 ? .hatchGreen : .hatchOrange)

            Button(action: { session.selectedTabIndex = 1 }) {
                statCard("PENDING APPROVALS", value: "\(viewModel.pendingCount)",
                         detail: viewModel.pendingCount == 0 ? "Queue clear" : "Review now ›",
                         detailColor: viewModel.pendingCount == 0 ? .secondary : .hatchOrange)
            }
            .buttonStyle(.plain)

            statCard("EGGS INCUBATING", value: viewModel.eggsIncubating.formatted(),
                     detail: "\(viewModel.activeCount) active batches", detailColor: .secondary)
        }
    }

    private func statCard(_ title: String, value: String, detail: String, detailColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.hatchGreen)
                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(detailColor)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
    }

    private var yieldCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CHICKS DELIVERED").font(.caption.weight(.bold)).tracking(1.1).foregroundColor(.secondary)
                Text(viewModel.chicksDelivered.formatted()).font(.title2.weight(.bold)).foregroundColor(.hatchGreen)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("BATCHES CLOSED").font(.caption.weight(.bold)).tracking(1.1).foregroundColor(.secondary)
                Text("\(viewModel.batchesClosed)").font(.title2.weight(.bold)).foregroundColor(.hatchGreen)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
    }

    private var productionStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CURRENT LIFECYCLE")
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundColor(Color.white.opacity(0.78))

            if let plan = viewModel.nextHatch {
                Text("Next Hatch: \(plan.batchID)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text("\(plan.site.name) • \(plan.requiredEggs.formatted()) eggs • due \(plan.hatchDate)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                HStack {
                    Spacer()
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.15), lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: plan.incubationProgress())
                            .stroke(Color.hatchOrange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("Day \(plan.incubationDay())")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text("OF \(ProductionCalculator.incubationDays)")
                                .font(.caption2.weight(.bold))
                                .opacity(0.75)
                        }
                        .foregroundColor(.white)
                    }
                    .frame(width: 112, height: 112)
                    Spacer()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Incubation day \(plan.incubationDay()) of \(ProductionCalculator.incubationDays)")

                NavigationLink(destination: BatchDetailView(planID: plan.id)) {
                    Text("VIEW DETAILS")
                        .font(.caption.weight(.bold))
                        .tracking(1.1)
                        .foregroundColor(.hatchGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white))
                }
            } else {
                Text("No batches incubating")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [.hatchGreenDeep, .hatchGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: .hatchGreen.opacity(0.2), radius: 18, x: 0, y: 10)
    }
}

#Preview {
    NavigationStack {
        ManagerHomeView()
            .environmentObject(AppSessionViewModel())
    }
}
