import SwiftUI

struct SupervisorScheduleView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel = SupervisorScheduleViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hatchSurface.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - Search Bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search batches or breed type...", text: $viewModel.searchText)
                                .textFieldStyle(.plain)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)

                        // MARK: - Scheduled Batches by Date
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(viewModel.groupedSchedules, id: \.date) { dateGroup in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Date Header
                                    Text(dateGroup.date.uppercased())
                                        .font(.caption.weight(.bold))
                                        .kerning(1)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)

                                    // Batch Cards for this Date
                                    VStack(spacing: 12) {
                                        ForEach(dateGroup.batches) { batch in
                                            NavigationLink(destination: SupervisorHatchDetailsView(batch: batch)) {
                                                scheduledBatchCard(batch)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }

                        // MARK: - Efficiency Forecast
                        VStack(alignment: .leading, spacing: 12) {
                            Text("EFFICIENCY FORECAST")
                                .font(.caption.weight(.bold))
                                .kerning(1)
                                .foregroundColor(.white)

                            Text(viewModel.efficiencyForecastTitle)
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                ProgressView(value: viewModel.efficiencyForecastPercentage)
                                    .tint(Color(hex: "#FFD700"))
                                    .frame(height: 6)

                                Text(String(format: "%.0f%%", viewModel.efficiencyForecastPercentage * 100))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.hatchGreen))
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .onAppear {
                session.fetchScheduledBatches()
                viewModel.loadData(from: session)
            }
            .onChange(of: session.scheduledBatches) { _ in
                viewModel.loadData(from: session)
            }
        }
    }

    private func scheduledBatchCard(_ batch: ScheduledBatch) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Time
            VStack(alignment: .center, spacing: 2) {
                Text(batch.time)
                    .font(.headline.bold())
                    .foregroundColor(.hatchGreen)
                Text(batch.timeOfDay)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, alignment: .center)

            // Batch Details
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(batch.batchID)
                        .font(.headline)
                        .foregroundColor(.hatchGreen)

                    if !batch.status.isEmpty {
                        Text(batch.status)
                            .font(.caption2.weight(.bold))
                            .kerning(0.8)
                            .foregroundColor(.white)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(batch.statusColor))
                    }
                }

                Text(batch.breed)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(batch.eggs) Eggs")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.hatchGreen)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
