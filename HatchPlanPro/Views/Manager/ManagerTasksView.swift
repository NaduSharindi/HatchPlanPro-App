import SwiftUI
import MapKit

struct ManagerMapView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9319, longitude: 79.8478),
        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    )

    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $region, interactionModes: .all, annotationItems: session.pendingPlans.isEmpty ? [] : [ManagerMapPin(coordinate: region.center)]) { pin in
                MapMarker(coordinate: pin.coordinate, tint: .hatchGreen)
            }
            .ignoresSafeArea()

            LinearGradient(colors: [Color.white.opacity(0.94), Color.white.opacity(0.1)], startPoint: .top, endPoint: .center)
                .frame(height: 120)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Spacer()

                if let plan = session.pendingPlans.first {
                    approvalCard(plan: plan)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 34)
                } else {
                    emptyMapState
                        .padding(.horizontal, 20)
                        .padding(.bottom, 34)
                }

                Spacer(minLength: 110)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "arrow.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.hatchGreen)
                    .frame(width: 42, height: 42)
            }

            Spacer()

            Text("HatchPlan Pro")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.hatchGreen)

            Spacer()

            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.hatchGreen)
                    .frame(width: 42, height: 42)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .background(Color.white.opacity(0.96))
    }

    private func approvalCard(plan: HatchPlanRecord) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 48, height: 6)
                .frame(maxWidth: .infinity)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("APPROVAL PENDING")
                        .font(.caption.weight(.bold))
                        .tracking(1.6)
                        .foregroundColor(.hatchGreen)
                    Text("Plan Review:\n\(plan.batchID), \(plan.location)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("TARGET CHICKS")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                    Text("\(plan.targetChicks) CHICKS")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.hatchSurface))
            }

            HStack(spacing: 12) {
                metricTile(title: "4,500", subtitle: "SHAVALS NEEDED", icon: "drop.fill", accent: .hatchGreenSoft, tint: .hatchGreen)
                metricTile(title: "15%", subtitle: "BUFFER APPLIED", icon: "chart.bar.fill", accent: Color.hatchOrangeSoft, tint: .hatchOrange)
            }

            NavigationLink(destination: ManagerApprovalPlanView(plan: session.pendingPlans.first)) {
                Text("View Plan Details >")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.hatchGreen)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)

            HStack(spacing: 14) {
                actionButton(title: "Reject", systemImage: "xmark", foreground: .red, background: .white, border: Color.red.opacity(0.25)) {
                    session.rejectPlan(batchID: plan.batchID)
                }
                actionButton(title: "Approve", systemImage: "checkmark", foreground: .white, background: .hatchGreen, border: .hatchGreen) {
                    session.approvePlan(batchID: plan.batchID)
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white))
        .shadow(color: .black.opacity(0.10), radius: 20, x: 0, y: 12)
    }

    private var emptyMapState: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.hatchGreen)
            Text("No plans yet")
                .font(.headline.weight(.semibold))
            Text("When a supervisor submits a plan, it will appear here for location-based review.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white))
    }

    private func metricTile(title: String, subtitle: String, icon: String, accent: Color, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(tint)

            Text(title)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption.weight(.bold))
                .foregroundColor(tint)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(accent))
    }

    private func actionButton(title: String, systemImage: String, foreground: Color, background: Color, border: Color, action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.headline.weight(.semibold))
        .foregroundColor(foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(background))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(border, lineWidth: background == .white ? 1.5 : 0))
        .onTapGesture(perform: action)
    }
}

private struct ManagerMapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    ManagerMapView()
}
