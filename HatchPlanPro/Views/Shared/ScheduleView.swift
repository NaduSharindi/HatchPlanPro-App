//
//  ScheduleView.swift
//  HatchPlanPro
//
//  Upcoming set, transfer and hatch milestones for both roles.
//

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var searchText = ""

    /// Groups by day while keeping the session's chronological order.
    private var groups: [(label: String, batches: [ScheduledBatch])] {
        let filtered = session.scheduledBatches.filter { batch in
            searchText.isEmpty
                || batch.batchID.localizedCaseInsensitiveContains(searchText)
                || batch.breed.localizedCaseInsensitiveContains(searchText)
        }
        var result: [(label: String, batches: [ScheduledBatch])] = []
        for batch in filtered {
            if let index = result.firstIndex(where: { $0.label == batch.dateLabel }) {
                result[index].batches.append(batch)
            } else {
                result.append((batch.dateLabel, [batch]))
            }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(title: "Schedule")

                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search batches or breed type...", text: $searchText)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
                .padding(.horizontal, 16)

                if groups.isEmpty {
                    ContentUnavailableView("Nothing Scheduled", systemImage: "calendar",
                                           description: Text("Approved and incubating batches appear here with their next milestone."))
                }

                ForEach(groups, id: \.label) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.label)
                            .font(.caption.weight(.bold))
                            .kerning(1)
                            .foregroundColor(group.label.hasPrefix("OVERDUE") ? .red : .secondary)
                            .padding(.horizontal, 16)

                        VStack(spacing: 0) {
                            ForEach(group.batches) { batch in
                                NavigationLink(destination: BatchDetailView(planID: batch.id)) {
                                    row(batch)
                                }
                                .buttonStyle(.plain)
                                if batch.id != group.batches.last?.id { Divider().padding(.leading, 80) }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
                        .padding(.horizontal, 16)
                    }
                }

                forecastCard
            }
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { session.fetchScheduledBatches() }
    }

    private func row(_ batch: ScheduledBatch) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text(batch.time).font(.headline.bold())
                Text(batch.timeOfDay).font(.caption).foregroundColor(.secondary)
            }
            .frame(width: 52)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(batch.batchID).font(.headline)
                    Spacer()
                    if !batch.status.isEmpty {
                        Text(batch.status)
                            .font(.caption2.weight(.bold))
                            .kerning(0.6)
                            .foregroundColor(batch.status == "CRITICAL" ? .black : .white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(Capsule().fill(batch.statusColor))
                    }
                }
                Text("\(batch.breed) • \(batch.eggs.formatted()) Eggs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding(16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var forecastCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EFFICIENCY FORECAST")
                .font(.caption.weight(.bold))
                .kerning(1.2)
                .foregroundColor(.white.opacity(0.8))
            Text(session.efficiencyForecast.title)
                .font(.title2.bold())
                .foregroundColor(.white)
            HStack(spacing: 12) {
                ProgressView(value: session.efficiencyForecast.percentage)
                    .tint(Color(hex: "#FFD966"))
                Text(session.efficiencyForecast.percentage.formatted(.percent.precision(.fractionLength(0))))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.hatchGreen))
        .padding(.horizontal, 16)
    }
}

/// Standard in-content header: back arrow (when pushed), centred title and an
/// optional trailing control. Used instead of the system bar for Figma parity.
struct ScreenHeader<Trailing: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    let title: String
    var showsBack = true
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack {
            if showsBack && isPresented {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.hatchGreen)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("Back")
            } else {
                Color.clear.frame(width: 40, height: 40)
            }
            Spacer()
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.hatchGreen)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            trailing()
                .frame(minWidth: 40, minHeight: 40)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, showsBack: Bool = true) {
        self.title = title
        self.showsBack = showsBack
        self.trailing = { EmptyView() }
    }
}
