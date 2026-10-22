import SwiftUI

struct ManagerPlanApprovedView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSessionViewModel
    let planID: String

    private var plan: HatchPlanRecord? { session.plan(withID: planID) }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }
                .accessibilityLabel("Back")
                Spacer()
                Text("Approval Status")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.hatchGreen)
                Spacer()
                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 100, height: 100)
                .background(Circle().fill(Color.hatchGreen))
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Plan Approved!")
                    .font(.system(size: 32, weight: .bold))
                Text("The plan for Order **\(plan?.batchID ?? "")** at \(plan?.site.name ?? "the site") has been successfully authorized.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "signature")
                        .font(.title2)
                        .foregroundColor(.hatchGreen)
                        .frame(width: 50, height: 50)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.15)))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DIGITAL SIGNATURE")
                            .font(.caption2.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.secondary)
                        Text(plan?.approvalSignature ?? "—")
                            .font(.subheadline)
                    }
                    Spacer(minLength: 0)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("BATCH TIMELINE")
                            .font(.caption2.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.secondary)
                        Text("\(ProductionCalculator.incubationDays) Days Projected")
                            .font(.headline.weight(.bold))
                        Text("Set \(plan?.eggSetDate ?? "") → Hatch \(plan?.hatchDate ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.08)))
            }
            .padding(.horizontal, 20)

            Spacer()

            NavigationLink(destination: ManagerReportPreviewView(planID: planID)) {
                Label("Generate PDF Report", systemImage: "doc.richtext")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.hatchGreen))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
