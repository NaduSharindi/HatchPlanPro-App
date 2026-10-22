//
//  PlanSubmittedView.swift
//  HatchPlanPro
//
//  Confirmation shown after a supervisor sends a plan for approval.
//

import SwiftUI

struct PlanSubmittedView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSessionViewModel
    let plan: HatchPlanRecord

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 100, height: 100)
                .background(Circle().fill(Color.hatchGreen))
                .shadow(color: .hatchGreen.opacity(0.3), radius: 16, y: 8)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Request Sent to Manager")
                    .font(.title2.weight(.bold))
                Text("Your plan for \(plan.targetChicks.formatted()) chicks (\(plan.requiredEggs.formatted()) eggs) has been submitted for final review.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 0) {
                row("RECIPIENT", "Operations Manager")
                Divider()
                row("SENT", (plan.submittedAt ?? Date()).formatted(date: .omitted, time: .shortened))
                Divider()
                row("SITE", plan.site.name)
                Divider()
                row("CUSTOMER", plan.customerName)
                Divider()
                HStack {
                    Text("BATCH").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                    Spacer()
                    Text(plan.batchID)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.hatchGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.hatchGreenSoft))
                }
                .padding(.vertical, 14)
                Divider()
                row("SYNC", session.pendingSyncCount > 0 ? "Saved offline – will sync" : "Synced to cloud")
            }
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))

            Spacer()

            Button(action: { dismiss() }) {
                Text("Return to Dashboard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreenDeep))
            }
        }
        .padding(24)
        .background(Color.hatchSurface.ignoresSafeArea())
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.caption.weight(.semibold)).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline)
        }
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }
}
