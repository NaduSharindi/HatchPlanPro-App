//
//  BatchClosingView.swift
//  HatchPlanPro
//
//  Closing step: the supervisor logs chicks pulled on hatch day and the app
//  calculates hatchability and variance against the order and standard.
//

import SwiftUI

struct BatchClosingView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @Environment(\.dismiss) private var dismiss
    let planID: String

    @State private var actualText = ""
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var showEarlyCloseWarning = false
    @FocusState private var focused: Bool

    private var plan: HatchPlanRecord? { session.plan(withID: planID) }
    private var actual: Int? { Int(actualText.filter(\.isNumber)) }

    var body: some View {
        ScrollView {
            if let plan {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("BATCH \(plan.batchID)").font(.caption.weight(.bold)).foregroundColor(.hatchOrange)
                        Text("Log Hatch Results").font(.title.weight(.bold))
                        Text("\(plan.requiredEggs.formatted()) eggs set on \(plan.eggSetDate) at \(plan.site.name).")
                            .font(.subheadline).foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CHICKS HATCHED").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                        TextField("e.g. \(plan.expectedChicks.formatted())", text: $actualText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.hatchGreen)
                            .focused($focused)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                            .accessibilityLabel("Chicks hatched")
                    }

                    if let actual, actual > 0 {
                        varianceCard(plan, actual: actual)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("SUPERVISOR NOTES").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                        TextField("Chick quality, culls, hatch window, anomalies…", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                    }

                    Button(action: { attemptClose(plan) }) {
                        Label("Close Batch", systemImage: "checkmark.seal")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 12).fill(actual == nil ? Color.gray.opacity(0.5) : Color.hatchGreen))
                    }
                    .disabled(actual == nil)
                }
                .padding(16)
            }
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationTitle("Close Batch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
            }
        }
        .alert("Close Before Hatch Day?", isPresented: $showEarlyCloseWarning) {
            Button("Close Anyway", role: .destructive) { close() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This batch is only on day \(plan?.incubationDay() ?? 0) of \(ProductionCalculator.incubationDays). Closing records the result now and cancels its remaining reminders.")
        }
        .alert("Unable to Close", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func varianceCard(_ plan: HatchPlanRecord, actual: Int) -> some View {
        let rate = Double(actual) / Double(max(plan.requiredEggs, 1))
        let hatchVariance = rate - plan.standardHatchability
        let orderVariance = actual - plan.targetChicks
        let good = orderVariance >= 0

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                metric("HATCHABILITY", rate.formatted(.percent.precision(.fractionLength(1))))
                metric("STANDARD", plan.standardHatchability.formatted(.percent.precision(.fractionLength(1))))
            }
            HStack {
                metric("VS STANDARD", (hatchVariance >= 0 ? "+" : "") + hatchVariance.formatted(.percent.precision(.fractionLength(1))))
                metric("VS ORDER", (orderVariance >= 0 ? "+" : "") + orderVariance.formatted() + " chicks")
            }
            Label(good ? "Order of \(plan.targetChicks.formatted()) chicks fulfilled." : "Short of the \(plan.targetChicks.formatted()) chick order.",
                  systemImage: good ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(good ? .hatchGreen : Color(hex: "#B3261E"))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(good ? Color.hatchGreenSoft : Color(hex: "#FDECEA")))
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2.weight(.bold)).foregroundColor(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func attemptClose(_ plan: HatchPlanRecord) {
        focused = false
        if plan.incubationDay() < ProductionCalculator.incubationDays {
            showEarlyCloseWarning = true
        } else {
            close()
        }
    }

    private func close() {
        guard let actual else { return }
        do {
            try session.closeBatch(planID: planID, actualChicks: actual, notes: notes)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
