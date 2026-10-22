import SwiftUI
import MapKit

struct ManagerApprovalPlanView: View {
    @EnvironmentObject var session: AppSessionViewModel
    @Environment(\.dismiss) var dismiss

    let plan: HatchPlanRecord?

    private var batchID: String { plan?.batchID ?? "#B1024" }
    private var date: String { plan?.eggSetDate ?? "Oct 24, 2023" }
    private var status: String { plan?.status.displayName ?? "PENDING" }
    private var statusColor: Color { plan?.status.color ?? Color(hex: "#F4C542") }

    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 6.9319, longitude: 79.8478), span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06))

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button(action: {
                    session.rejectPlan(batchID: batchID)
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }
                Spacer()
                Text("Batch Details")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.hatchGreen)
                Spacer()
                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView {
                VStack(spacing: 20) {
                    // ID Card
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("BATCH ID")
                                .font(.caption2.weight(.bold))
                                .kerning(1)
                                .foregroundColor(.secondary)
                            Text(batchID)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.caption)
                                Text("Meegoda Prima Farm")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            Text(status)
                                .font(.caption2.weight(.bold))
                                .kerning(0.5)
                                .foregroundColor(.black)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Capsule().fill(statusColor))
                            
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .foregroundColor(.hatchOrange)
                                Text("4 Days Left")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.hatchOrange)
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)

                    // Stat tiles
                    HStack(spacing: 12) {
                        statTile(title: "TARGET EGG SET", value: "14,500", icon: "clipboard", bg: Color.white)
                        statTile(title: "SAFETY BUFFER", value: "15%", icon: "shield.checkerboard", bg: Color(hex: "#FDD835"))
                    }
                    .padding(.horizontal, 16)

                    HStack(spacing: 12) {
                        statTile(title: "SHAVALS REQUIRED", value: "450 Units", icon: "shippingbox", bg: Color.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    // Timeline
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OPERATIONAL TIMELINE")
                            .font(.caption.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        HStack(spacing: 12) {
                            timelineTile(title: "EGG SET DATE", value: "Oct 20, 2023", icon: "calendar", iconColor: .hatchGreen)
                            timelineTile(title: "HATCH DATE", value: "Nov 10, 2023", icon: "oval.portrait.fill", iconColor: .hatchOrange)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Source flocks
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Source Flocks")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                            Spacer()
                            Text("MULTI-BATCH ALLOCATION")
                                .font(.caption.weight(.bold))
                                .kerning(0.5)
                                .foregroundColor(.hatchGreen)
                        }
                        VStack(spacing: 12) {
                            sourceRow(id: "F-902", weeks: "34 weeks", allocated: "6,000")
                            sourceRow(id: "F-815", weeks: "26 weeks", allocated: "4,500")
                            sourceRow(id: "F-722", weeks: "34 weeks", allocated: "4,000")
                        }
                    }
                    .padding(.horizontal, 16)

                    // Map card
                    ZStack(alignment: .bottomLeading) {
                        Map(coordinateRegion: $region, interactionModes: .all, annotationItems: [ManagerPlanMapPin(coordinate: region.center)]) { pin in
                            MapMarker(coordinate: pin.coordinate, tint: .hatchGreen)
                        }
                        .frame(height: 160)
                        .cornerRadius(20)
                        
                        LinearGradient(colors: [.black.opacity(0), .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                            .cornerRadius(20)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.hatchGreen)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Station C-9")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.white)
                                Text("Hatchery Main Sector")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal, 16)

                    // Batch Records grid
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Batch Records")
                                .font(.headline.bold())
                                .foregroundColor(.hatchGreen)
                            Spacer()
                            Text("View All (9)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                            ForEach(0..<5) { idx in
                                Image("record_placeholder_\(idx % 3)") // Placeholder, should be replaced with actual images
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 80)
                                    .clipped()
                                    .cornerRadius(12)
                            }
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2))
                                Text("+4")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 80)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 40)
                }
            }

            // Bottom Buttons
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Reject")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.15)))
                }
                
                Button(action: {
                    session.approvePlan(batchID: batchID, reviewedBy: session.currentUser.fullName)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Approve Plan")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.hatchGreen))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func statTile(title: String, value: String, icon: String, bg: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(bg == .white ? .hatchGreen : .black.opacity(0.6))
                .padding(.bottom, 4)
            
            Text(title)
                .font(.caption2.weight(.bold))
                .kerning(0.5)
                .foregroundColor(bg == .white ? .secondary : .black.opacity(0.7))
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(bg))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private func timelineTile(title: String, value: String, icon: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .padding(10)
                .background(Circle().fill(iconColor.opacity(0.1)))
            
            Text(title)
                .font(.caption2.weight(.bold))
                .kerning(0.5)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.hatchGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private func sourceRow(id: String, weeks: String, allocated: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .foregroundColor(.hatchGreen)
                .padding(12)
                .background(Circle().fill(Color.hatchGreenSoft))
            VStack(alignment: .leading, spacing: 4) {
                Text(id)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.black)
                Text(weeks)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(allocated)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.hatchGreen)
                Text("ALLOCATED")
                    .font(.caption2.weight(.bold))
                    .kerning(0.5)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct ManagerPlanMapPin: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

#Preview {
    NavigationStack {
        ManagerApprovalPlanView(plan: nil)
            .environmentObject(AppSessionViewModel())
    }
}
