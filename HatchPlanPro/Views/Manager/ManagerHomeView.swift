import SwiftUI

struct ManagerHomeView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    private let comparativeMonths: [(label: String, standard: CGFloat, active: CGFloat)] = [
        ("OCT", 0.48, 0.42),
        ("NOV", 0.58, 0.63),
        ("DEC", 0.45, 0.49),
        ("JAN", 0.61, 0.67),
        ("FEB", 0.55, 0.72),
        ("MAR", 0.68, 0.76)
    ]

    private let quickStats: [(title: String, value: String, subtitle: String)] = [
        ("FERTILITY RATE", "91.2%", "+0.4%"),
        ("CHICK QUALITY", "A+", "Top tier"),
        ("7-DAY MORTALITY", "0.8%", "Stable")
    ]

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
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 12) {
                AppLogoView(size: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text("HatchPlan Pro")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.hatchGreen)

                    Text("Meegoda Hatchery")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: {}) {
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

    private var analyticsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("COMPARATIVE ANALYTICS")
                        .font(.caption.weight(.bold))
                        .tracking(1.8)
                        .foregroundColor(.hatchOrange)
                    Text("Hatchability Performance")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }

                Spacer()

                HStack(spacing: 14) {
                    legendItem(color: .hatchGreen, label: "STANDARD")
                    legendItem(color: .hatchOrange, label: "ACTUAL")
                }
            }

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(comparativeMonths.enumerated()), id: \.element.label) { index, month in
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.hatchGreenSoft)
                                .frame(width: 12, height: 118)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.hatchOrange)
                                .frame(width: 12, height: 118 * month.active)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.hatchGreen)
                                .frame(width: 12, height: 118 * month.standard)
                                .offset(x: 16)
                        }
                        .frame(width: 28, height: 118, alignment: .bottom)

                        Text(month.label)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(0.96)
                    .padding(.top, index == 0 ? 0 : 6)
                }
            }
            .frame(height: 164)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 8)
    }

    private var statusCards: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: ManagerScheduleView()) {
                navigationSummaryCard(title: "Ongoing Hatches", subtitle: "View monitoring active", icon: "circle.grid.2x2.fill")
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: ManagerBatchHistoryListView()) {
                navigationSummaryCard(title: "Completed Batches", subtitle: "Batch performance history", icon: "tray.full.fill")
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
            ForEach(Array(quickStats.enumerated()), id: \.element.title) { index, stat in
                VStack(alignment: .leading, spacing: 6) {
                    Text(stat.title)
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundColor(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 10) {
                        Text(stat.value)
                            .font(.system(size: index == 0 ? 28 : 26, weight: .bold, design: .rounded))
                            .foregroundColor(.hatchGreen)
                        Text(stat.subtitle)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(index == 1 ? .hatchOrange : .secondary)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
            }
        }
    }

    private var yieldCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FERTILITY RATE")
                .font(.caption.weight(.bold))
                .tracking(1.3)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("91.2%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.hatchGreen)
                Text("+0.4%")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.hatchGreen)
            }

            Divider().opacity(0.45)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CHICK QUALITY")
                        .font(.caption.weight(.bold))
                        .tracking(1.1)
                        .foregroundColor(.secondary)
                    Text("A+")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("7-DAY MORTALITY")
                        .font(.caption.weight(.bold))
                        .tracking(1.1)
                        .foregroundColor(.secondary)
                    Text("0.8%")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private var productionStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CURRENT LIFECYCLE")
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundColor(Color.white.opacity(0.78))
            Text("Active Yield Forecast")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)

            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Text("84%")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("CONFIDENCE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundColor(Color.white.opacity(0.75))
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Circle()
                            .trim(from: 0, to: 0.84)
                            .stroke(Color.hatchOrange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 112, height: 112)
                    )
            )

            Button(action: {}) {
                Text("VIEW DETAILS")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundColor(.hatchGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white))
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

private func legendItem(color: Color, label: String) -> some View {
    HStack(spacing: 6) {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
        Text(label)
            .font(.caption2.weight(.bold))
            .foregroundColor(.secondary)
    }
}

private struct AvatarInitialsView: View {
    let initials: String

    var body: some View {
        Text(initials)
            .font(.subheadline.weight(.bold))
            .foregroundColor(.hatchGreen)
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color.white))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        ManagerHomeView()
            .environmentObject(AppSessionViewModel())
    }
}
