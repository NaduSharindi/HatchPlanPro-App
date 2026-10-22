//
//  ManagerApprovalPlanView.swift
//  HatchPlanPro
//
//  Verification step: the manager reviews the calculation side by side with
//  the site map and source certificate, then signs or rejects.
//

import SwiftUI

struct ManagerApprovalPlanView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @Environment(\.dismiss) private var dismiss

    let planID: String

    @State private var showRejectSheet = false
    @State private var isSigning = false
    @State private var showApproved = false
    @State private var errorMessage: String?

    private var plan: HatchPlanRecord? { session.plan(withID: planID) }

    var body: some View {
        VStack(spacing: 0) {
            header

            if let plan {
                ScrollView {
                    VStack(spacing: 16) {
                        idCard(plan)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                            BatchStatTile(title: "TARGET EGG SET", value: plan.requiredEggs.formatted(), icon: "list.clipboard")
                            BatchStatTile(title: "SAFETY BUFFER", value: plan.safetyBuffer.formatted(.percent.precision(.fractionLength(1))), icon: "checkmark.shield", highlighted: true)
                            BatchStatTile(title: "SETTER TRAYS", value: "\(plan.setterTrays) Units", icon: "tray.full")
                            BatchStatTile(title: "TARGET CHICKS", value: plan.targetChicks.formatted(), icon: "bird")
                        }
                        SiteMapCard(site: plan.site, height: 170)
                        CalculationBreakdownCard(plan: plan)
                        timeline(plan)
                        flockRow(plan)
                        CertificateRecordCard(plan: plan)
                        historyHint(plan)
                    }
                    .padding(16)
                }
                if plan.status == .pendingReview {
                    actionBar(plan)
                } else {
                    Label("This plan is \(plan.status.displayName.lowercased()).", systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                }
            } else {
                ContentUnavailableView("Plan Unavailable", systemImage: "doc.questionmark")
            }
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showRejectSheet) {
            RejectPlanSheet(batchID: plan?.batchID ?? "") { reason in
                do {
                    try session.rejectPlan(planID: planID, reason: reason)
                    showRejectSheet = false
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .navigationDestination(isPresented: $showApproved) {
            ManagerPlanApprovedView(planID: planID)
        }
        .alert("Approval Not Applied", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.hatchGreen)
            }
            .accessibilityLabel("Back")
            Spacer()
            Text("Plan Review").font(.headline.weight(.bold)).foregroundColor(.hatchGreen)
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
        .padding()
        .background(Color.white)
    }

    private func idCard(_ plan: HatchPlanRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BATCH ID").font(.caption2.weight(.bold)).kerning(1).foregroundColor(.hatchOrange)
                    Text(plan.batchID).font(.system(size: 30, weight: .bold)).foregroundColor(.hatchGreenDeep)
                }
                Spacer()
                BatchStatusBadge(status: plan.status)
            }
            Label(plan.site.name, systemImage: "mappin.and.ellipse").font(.subheadline)
            if !plan.customerName.isEmpty {
                Label("Order for \(plan.customerName)", systemImage: "cart").font(.subheadline)
            }
            Label("Requested by \(plan.createdBy) • \((plan.submittedAt ?? plan.createdAt).formatted(date: .abbreviated, time: .shortened))",
                  systemImage: "person.crop.circle")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
    }

    private func timeline(_ plan: HatchPlanRecord) -> some View {
        HStack(spacing: 12) {
            tile("EGG SET", plan.eggSetDate, icon: "calendar.badge.plus")
            tile("TRANSFER", plan.transferDate.formatted(date: .abbreviated, time: .omitted), icon: "arrow.right.square")
            tile("HATCH", plan.hatchDate, icon: "oval.portrait.fill")
        }
    }

    private func tile(_ title: String, _ value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundColor(.hatchGreen)
            Text(title).font(.caption2.weight(.semibold)).foregroundColor(.secondary)
            Text(value).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .accessibilityElement(children: .combine)
    }

    private func flockRow(_ plan: HatchPlanRecord) -> some View {
        HStack {
            Image(systemName: "leaf.circle.fill").font(.title2).foregroundColor(.hatchGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(plan.flockID) • \(plan.breed.rawValue)").font(.subheadline.weight(.semibold))
                Text("\(plan.flockAgeWeeks) weeks old").font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Text(plan.requiredEggs.formatted()).font(.headline).foregroundColor(.hatchGreen)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .accessibilityElement(children: .combine)
    }

    /// Recent performance of the same breed at this site, to judge the buffer.
    @ViewBuilder
    private func historyHint(_ plan: HatchPlanRecord) -> some View {
        let comparable = session.completedPlans.filter { $0.siteID == plan.siteID && $0.breed == plan.breed }.prefix(5)
        let rates = comparable.compactMap(\.actualHatchability)
        if !rates.isEmpty {
            let average = rates.reduce(0, +) / Double(rates.count)
            let gap = average - plan.standardHatchability
            Label {
                Text("Last \(rates.count) \(plan.breed.rawValue) batches at this site averaged \(average.formatted(.percent.precision(.fractionLength(1)))) (\(gap >= 0 ? "+" : "")\(gap.formatted(.percent.precision(.fractionLength(1)))) vs this plan's standard).")
            } icon: {
                Image(systemName: gap >= 0 ? "chart.line.uptrend.xyaxis" : "exclamationmark.triangle.fill")
            }
            .font(.caption)
            .foregroundColor(gap >= 0 ? .hatchGreen : Color(hex: "#9A6B00"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(gap >= 0 ? Color.hatchGreenSoft : Color(hex: "#FFF9E6")))
        }
    }

    private func actionBar(_ plan: HatchPlanRecord) -> some View {
        HStack(spacing: 14) {
            Button(action: { showRejectSheet = true }) {
                Label("Reject", systemImage: "xmark")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.15)))
            }
            .disabled(isSigning)

            Button(action: approve) {
                HStack {
                    if isSigning { ProgressView().tint(.white) } else { Image(systemName: "checkmark.seal") }
                    Text("Approve Plan")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.hatchGreenDeep))
            }
            .disabled(isSigning)
            .accessibilityHint("Requires Face ID, Touch ID or your passcode as a digital signature.")
        }
        .padding(16)
        .background(Color.white)
    }

    private func approve() {
        isSigning = true
        Task {
            do {
                try await session.approvePlan(planID: planID)
                showApproved = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSigning = false
        }
    }
}

/// Collects the mandatory rejection reason sent back to the supervisor.
struct RejectPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    let batchID: String
    let onReject: (String) -> Void

    @State private var reason = ""

    private let quickReasons = [
        "Safety buffer too low for this flock age.",
        "Flock is past optimal laying age; source a younger flock.",
        "Setter capacity at this site is already committed.",
        "Certificate is unreadable or missing. Rescan and resubmit."
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick reasons") {
                    ForEach(quickReasons, id: \.self) { option in
                        Button(option) { reason = option }
                            .foregroundColor(.primary)
                    }
                }
                Section("Message to supervisor") {
                    TextField("Explain what needs to change", text: $reason, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Reject \(batchID)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Reject", role: .destructive) { onReject(reason) }
                        .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
