//
//  ManagerReportPreviewView.swift
//  HatchPlanPro
//
//  Generates the batch's PDF performance audit, previews it with PDFKit and
//  shares it through the system share sheet.
//

import SwiftUI

struct ManagerReportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSessionViewModel
    let planID: String

    @State private var reportURL: URL?
    @State private var errorMessage: String?

    private var plan: HatchPlanRecord? { session.plan(withID: planID) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }
                .accessibilityLabel("Close")
                Spacer()
                Text("Report Preview")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.hatchGreen)
                Spacer()
                if let reportURL, let plan {
                    ShareLink(item: reportURL,
                              subject: Text("HatchPlan Pro report \(plan.batchID)"),
                              message: Text("Performance and traceability report for \(plan.batchID).")) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.hatchGreen)
                    }
                    .accessibilityLabel("Share PDF report")
                } else {
                    Color.clear.frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .background(Color.white)

            if let reportURL {
                PDFKitView(url: reportURL)
            } else if let errorMessage {
                ContentUnavailableView("Report Failed", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
            } else {
                ProgressView("Generating report…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: plan?.updatedAt) {
            generate()
        }
    }

    private func generate() {
        guard let plan else {
            errorMessage = "This batch is no longer available."
            return
        }
        do {
            reportURL = try PerformanceReportGenerator.generate(for: plan, generatedBy: session.currentUser.fullName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
