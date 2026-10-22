//
//  ExecuteSetSheetView.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-13.
//

import SwiftUI

struct ExecuteSetSheetView: View {
    @EnvironmentObject var session: AppSessionViewModel
    @Environment(\.dismiss) var dismiss
    let batchID: String
    @State private var isExecuting = false
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color(hex: "#EAEAEA"))
                .frame(width: 60, height: 6)
                .padding(.top, 12)

            Image(systemName: "checkmark")
                .font(.system(size: 36))
                .foregroundColor(.white)
                .padding(20)
                .background(Circle().fill(Color.hatchGreen))

            Text("Execute Set & Sync Calendar?")
                .font(.title2.weight(.bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

            Text("This will initiate the biological timer for 42,500 eggs and synchronize the 21-day incubation schedule across all management devices.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()

            Button(action: performExecute) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text(isExecuting ? "Executing…" : "Execute Set")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
                .padding(.horizontal, 20)
            }
            .disabled(isExecuting)

            Button(action: { dismiss() }) {
                Text("Cancel")
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 16)

            HStack {
                Text("SET DATE: TODAY")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("HATCH: OCT 24")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            ProgressView(value: 0.1)
                .tint(Color(hex: "#997700"))
                .padding(.horizontal, 20)
        }
        .presentationDetents([.medium])
        .sheet(isPresented: $showSuccess) {
            BatchSetSuccessView(batchIDs: [batchID])
                .environmentObject(session)
        }
    }

    private func performExecute() {
        isExecuting = true
        session.executeSet(batchID: batchID) { success in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isExecuting = false
                if success {
                    showSuccess = true
                } else {
                    // handle failure (toast or alert)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ExecuteSetSheetView(batchID: "#B1024")
        .environmentObject(AppSessionViewModel())
}
