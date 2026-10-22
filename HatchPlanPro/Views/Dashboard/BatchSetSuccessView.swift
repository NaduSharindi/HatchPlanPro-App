//
//  BatchSetSuccessView.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-13.
//

import SwiftUI

struct BatchSetSuccessView: View {
    @EnvironmentObject var session: AppSessionViewModel
    @Environment(\.dismiss) var dismiss
    let batchIDs: [String]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.hatchGreen.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.hatchGreen)
            }

            Text("Batch Successfully Set")
                .font(.title2.weight(.bold))
                .foregroundColor(.black)

            Text("12,500 units have been synchronized with the incubation calendar and facility sensors.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("ACTIVE BATCH IDS")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(batchIDs, id: \.self) { id in
                            Text(id)
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.hatchGreen))
                        }
                    }
                }

                Divider()

                HStack {
                    Text("START TIME")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Today, 08:45 AM")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.black)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            .padding(.horizontal, 24)

            Spacer()

            Button(action: { dismiss() }) {
                Text("Return to Dashboard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 20)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
    }
}

#Preview {
    BatchSetSuccessView(batchIDs: ["#B1024", "#B1028", "#B1030"]) .environmentObject(AppSessionViewModel())
}
