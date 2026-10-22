import SwiftUI

struct SupervisorBatchesView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel = SupervisorBatchesViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Header
                    HStack {
                        Text("Hatchery Insights")
                            .font(.title2.bold())
                            .foregroundColor(.hatchGreen)
                        Spacer()
                        NavigationLink(destination: SupervisorProfileView()) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundColor(.hatchGreen)
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Approved & Ready
                    batchSection(
                        title: "APPROVED & READY",
                        count: "\(viewModel.approvedBatches.count) Items",
                        batches: viewModel.approvedBatches
                    )

                    // MARK: - Pending Manager Review
                    batchSection(
                        title: "PENDING MANAGER REVIEW",
                        count: "\(viewModel.pendingBatches.count) Items",
                        batches: viewModel.pendingBatches
                    )

                    // MARK: - Rejected / Action Required
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("REJECTED / ACTION REQUIRED")
                                .font(.caption.weight(.bold))
                                .kerning(1)
                            Spacer()
                            Text("\(viewModel.rejectedBatches.count) Items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 12) {
                            ForEach(viewModel.rejectedBatches) { item in
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.id)
                                            .font(.headline)
                                        Text(item.breed)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(item.date)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(item.status)
                                        .font(.caption2.weight(.bold))
                                        .kerning(0.8)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 10)
                                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(item.statusColor))
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FAFAFA")))

                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Target temperature too high for breed specification. Update and resubmit.")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    Spacer()
                                    NavigationLink(destination: ScannerIntroView().environmentObject(session)) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.hatchGreen)
                                    }
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#FAFAFA")))
                            }
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 16)

                    // MARK: - Calendar Synced
                    batchSection(
                        title: "CALENDAR SYNCED",
                        count: "\(viewModel.syncedBatches.count) Items",
                        batches: viewModel.syncedBatches
                    )

                    // MARK: - Supervisor Insight
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SUPERVISOR INSIGHT")
                            .font(.caption.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.white)
                        Text("Hatchery efficiency is up \(String(format: "%.1f", viewModel.efficiencyIncrease))% this week.")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.caption)
                                .foregroundColor(.hatchGreen)
                            Text(viewModel.reviewMessage)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.hatchGreen))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("Hatchery Insights")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadData(from: session)
            }
        }
    }

    private func batchSection(title: String, count: String, batches: [SupervisorBatchInsight]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .kerning(1)
                Spacer()
                Text(count)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(batches) { item in
                    NavigationLink(destination: BatchDetailView(batchID: item.batchID, breed: item.breed, date: item.date, status: item.status, statusColor: item.statusColor, canExecute: item.statusCode == .approvedReady || item.statusCode == .synced).environmentObject(session)) {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.batchID)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(item.breed)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(item.date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(item.status)
                                .font(.caption2.weight(.bold))
                                .kerning(0.8)
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(item.statusColor))
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FAFAFA")))
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}
