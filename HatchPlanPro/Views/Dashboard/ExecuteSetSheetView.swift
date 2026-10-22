//
//  ExecuteSetSheetView.swift
//  HatchPlanPro
//
//  Confirms the physical egg set, starts the 21-day biological timer and
//  syncs milestones to Calendar and local reminders.
//

import SwiftUI

struct ExecuteSetSheetView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @Environment(\.dismiss) private var dismiss
    let planID: String

    @AppStorage("execute.addToCalendar") private var addToCalendar = true
    @AppStorage("execute.addReminders") private var addReminders = true
    @State private var isExecuting = false
    @State private var outcome: ScheduleOutcome?
    @State private var errorMessage: String?

    private var plan: HatchPlanRecord? { session.plan(withID: planID) }
    private var hatchDate: Date { ProductionCalculator.hatchDate(from: Date()) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 84, height: 84)
                    .background(Circle().fill(Color.hatchGreen))
                    .padding(.top, 8)
                    .accessibilityHidden(true)

                Text("Execute Set & Sync Calendar?")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("This starts the biological timer for \(plan?.requiredEggs.formatted() ?? "–") eggs in \(plan?.setterTrays ?? 0) setter trays and schedules the \(ProductionCalculator.incubationDays)-day incubation milestones.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 0) {
                    Toggle("Add milestones to Calendar", isOn: $addToCalendar)
                    Divider().padding(.vertical, 8)
                    Toggle("Schedule transfer & hatch reminders", isOn: $addReminders)
                }
                .tint(.hatchGreen)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.hatchSurface))

                Spacer(minLength: 0)

                Button(action: execute) {
                    HStack {
                        if isExecuting { ProgressView().tint(.white) } else { Image(systemName: "bolt.fill") }
                        Text(isExecuting ? "Executing…" : "Execute Set")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreenDeep))
                }
                .disabled(isExecuting || plan?.status != .approvedReady)

                Button("Cancel") { dismiss() }
                    .foregroundColor(.secondary)

                VStack(spacing: 6) {
                    HStack {
                        Text("SET DATE: TODAY").foregroundColor(.secondary)
                        Spacer()
                        Text("HATCH: \(hatchDate.formatted(.dateTime.month(.abbreviated).day()).uppercased())")
                            .foregroundColor(.hatchOrange)
                    }
                    .font(.caption2.weight(.bold))
                    ProgressView(value: 0.05).tint(.hatchOrange)
                }
            }
            .padding(24)
            .navigationDestination(item: $outcome) { outcome in
                if let plan {
                    BatchSetSuccessView(plan: plan, outcome: outcome) { dismiss() }
                }
            }
            .alert("Unable to Execute", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(isExecuting)
    }

    private func execute() {
        isExecuting = true
        Task {
            do {
                outcome = try await session.executePlan(planID: planID, addToCalendar: addToCalendar, addReminders: addReminders)
            } catch {
                errorMessage = error.localizedDescription
            }
            isExecuting = false
        }
    }
}
