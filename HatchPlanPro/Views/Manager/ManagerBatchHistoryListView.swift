import SwiftUI

struct ManagerBatchHistoryListView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel = SupervisorHistoryViewModel()

    var body: some View {
        Group {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Header
                    HStack {
                        Text("Batch History")
                            .font(.title2.bold())
                            .foregroundColor(.hatchGreen)
                        Spacer()
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.hatchGreen)
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Quarterly Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("QUARTERLY SUMMARY")
                            .font(.caption.weight(.bold))
                            .kerning(1)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("AVERAGE HATCH RATE")
                                .font(.caption.weight(.bold))
                                .kerning(1)
                                .foregroundColor(.secondary)

                            HStack(alignment: .top, spacing: 20) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(String(format: "%.1f", viewModel.averageHatchRate * 100))%")
                                        .font(.system(size: 38, weight: .bold))
                                        .foregroundColor(.hatchGreen)
                                    ProgressView(value: viewModel.averageHatchRate)
                                        .tint(.hatchGreen)
                                        .frame(width: 120)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("TOTAL BATCHES")
                                        .font(.caption.weight(.bold))
                                        .kerning(1)
                                        .foregroundColor(.secondary)
                                    Text("\(viewModel.totalBatches)")
                                        .font(.title2.bold())
                                        .foregroundColor(.hatchGreen)
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: "#FAFAFA")))
                    }
                    .supervisorCard()
                    .padding(.horizontal, 16)

                    // MARK: - Monthly History
                    ForEach(viewModel.monthlyHistory) { month in
                        batchHistoryMonth(title: month.title, batches: month.batches)
                    }

                    if viewModel.monthlyHistory.isEmpty {
                        ContentUnavailableView("No Closed Batches", systemImage: "clock.arrow.circlepath",
                                               description: Text("Batches appear here once supervisors log hatch results."))
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("Batch History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .onReceive(session.$hatchPlans) { _ in
                viewModel.loadData(from: session)
            }
        }
    }

    private func batchHistoryMonth(title: String, batches: [BatchHistoryItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.bold))
                .kerning(1)

            VStack(spacing: 10) {
                ForEach(batches) { batch in
                    NavigationLink(destination: BatchDetailView(planID: batch.planID)) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(batch.id)
                                    .font(.headline)
                                    .foregroundColor(.hatchGreen)
                                Text(batch.site)
                                    .font(.subheadline)
                                Text(batch.date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(batch.rate)
                                .font(.headline)
                                .foregroundColor(batch.isBelowStandard ? .hatchOrange : .hatchGreen)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .supervisorCard()
        .padding(.horizontal, 16)
    }
}
