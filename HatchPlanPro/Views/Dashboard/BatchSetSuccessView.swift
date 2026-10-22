//
//  BatchSetSuccessView.swift
//  HatchPlanPro
//

import SwiftUI

struct BatchSetSuccessView: View {
    let plan: HatchPlanRecord
    let outcome: ScheduleOutcome
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 96, height: 96)
                .background(Circle().fill(Color.hatchGreen))
                .accessibilityHidden(true)

            Text("Batch Successfully Set")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.hatchGreenDeep)
                .multilineTextAlignment(.center)

            Text("\(plan.requiredEggs.formatted()) eggs are incubating. Hatch is due \(ProductionCalculator.hatchDate(from: Date()).formatted(date: .complete, time: .omitted)).")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 0) {
                row("ACTIVE BATCH ID", plan.batchID)
                Divider()
                row("START TIME", "Today, \(Date().formatted(date: .omitted, time: .shortened))")
                Divider()
                row("CALENDAR", outcome.calendarEventIDs.isEmpty ? "Not added" : "\(outcome.calendarEventIDs.count) milestones added")
                Divider()
                row("REMINDERS", outcome.remindersScheduled == 0 ? "None scheduled" : "\(outcome.remindersScheduled) scheduled")
            }
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))

            if let error = outcome.calendarError {
                Label(error, systemImage: "calendar.badge.exclamationmark")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#9A6B00"))
            }

            Spacer()

            Button(action: onFinish) {
                Text("Return to Batch")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreenDeep))
            }
        }
        .padding(24)
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.caption.weight(.semibold)).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }
}
