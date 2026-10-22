import SwiftUI

struct ManagerPlanApprovedView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }
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
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.hatchGreen)
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 16)
            
            // Text Content
            VStack(spacing: 12) {
                Text("Plan Approved!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text("The multi-batch plan for Order\n**#B1024** has been successfully\nauthorized.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding(.bottom, 24)
            
            // Status Cards
            VStack(spacing: 16) {
                // Report Status
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                        .foregroundColor(.hatchGreen)
                        .frame(width: 50, height: 50)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.15)))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("REPORT STATUS")
                                .font(.caption2.weight(.bold))
                                .kerning(1)
                                .foregroundColor(.secondary)
                            Spacer()
                            Circle().fill(Color(hex: "#8B6B23")).frame(width: 8, height: 8)
                        }
                        
                        Text("Ready for Generation")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.black)
                        
                        Text("All parameters verified and\nsynced.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
                
                // Batch Timeline
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("BATCH TIMELINE")
                            .font(.caption2.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.secondary)
                        Text("21 Days Projected")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    
                    HStack(spacing: -12) {
                        Image("egg_tray_photo") // Placeholder avatar/image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FDD835"))
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            Text("+3")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.08)))
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Action Button
            NavigationLink(destination: ManagerReportPreviewView()) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                    Text("Generate PDF Report")
                }
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
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        ManagerPlanApprovedView()
    }
}
