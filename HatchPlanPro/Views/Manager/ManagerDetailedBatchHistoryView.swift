import SwiftUI

struct ManagerDetailedBatchHistoryView: View {
    @Environment(\.dismiss) var dismiss

    let batchID: String
    let breed: String
    let date: String
    let status: String
    let statusColor: Color

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                chartSection
                statsSection
                yieldSummaryCard
                safetyBufferCard
                sourceFlocksSection
                operationalTimelineSection
                batchRecordsSection
                auditReportSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 30)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.hatchGreen)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Batch History")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.hatchGreen)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(batchID)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Text(status)
                    .font(.caption2.weight(.bold))
                    .kerning(0.8)
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Capsule().fill(statusColor))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("\(date) • Final Audit Passed")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                    Text("Meegoda Prima Farm")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hatchability")
                        .font(.headline.bold())
                    Text("Performance")
                        .font(.headline.bold())
                    Text("COMPARATIVE ANALYSIS")
                        .font(.caption.weight(.bold))
                        .kerning(1)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    legendItem(color: .hatchGreen, label: "STANDARD")
                    legendItem(color: .hatchOrange, label: "ACTUAL")
                }
            }

            // Dummy Bar Chart
            HStack(alignment: .bottom, spacing: 20) {
                chartBarGroup(label: "SET", standard: 0.6, actual: 0.75)
                chartBarGroup(label: "TRANS", standard: 0.55, actual: 0.65)
                chartBarGroup(label: "HATCH", standard: 0.95, actual: 0.85)
                chartBarGroup(label: "DISPATCH", standard: 0.45, actual: 0.55)
            }
            .frame(height: 140)
            .padding(.top, 10)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(title: "TOTAL EGGS SET", value: "14,500", subtitle: "OPTIMAL LOAD", icon: "arrow.up.right", isPositive: true)
            statCard(title: "SHAVALS USED", value: "450", subtitle: "STANDARD PACK", icon: nil, isPositive: nil)
        }
    }

    private var yieldSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YIELD SUMMARY")
                    .font(.caption.weight(.bold))
                    .kerning(1)
                    .foregroundColor(.black.opacity(0.6))
                Spacer()
                Image(systemName: "leaf.fill")
                    .foregroundColor(.black.opacity(0.6))
            }
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("13,673")
                        .font(.system(size: 38, weight: .bold))
                    Text("TOTAL CHICKS OUT")
                        .font(.caption.weight(.semibold))
                        .kerning(0.5)
                        .foregroundColor(.black.opacity(0.7))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("13,500")
                        .font(.title2.weight(.bold))
                    Text("HEALTHY")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.black.opacity(0.7))
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(hex: "#FDD835"))) // Yellowish
        .foregroundColor(.black)
    }

    private var safetyBufferCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "shield.fill")
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("SAFETY BUFFER RATE")
                    .font(.caption.weight(.bold))
                    .kerning(1)
                    .foregroundColor(.white.opacity(0.8))
                Text("15% Applied")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.hatchGreen))
    }

    private var sourceFlocksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Source Flocks")
                    .font(.headline.bold())
                Spacer()
                Text("MULTI-BATCH ALLOCATION")
                    .font(.caption.weight(.bold))
                    .kerning(0.8)
                    .foregroundColor(.hatchGreen)
            }

            VStack(spacing: 12) {
                flockRow(id: "F-902", age: "34 weeks", allocated: "6,000", healthy: "5,600")
                flockRow(id: "F-815", age: "36 weeks", allocated: "4,500", healthy: "4,210")
                flockRow(id: "F-722", age: "34 weeks", allocated: "4,000", healthy: "3,990")
            }
        }
    }

    private var operationalTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OPERATIONAL TIMELINE")
                .font(.caption.weight(.bold))
                .kerning(1)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                timelineCard(icon: "calendar.badge.plus", title: "EGG SET DATE", value: "Oct 20, 2023", color: .hatchGreen)
                timelineCard(icon: "oval.portrait.fill", title: "HATCH DATE", value: "Nov 10, 2023", color: .hatchOrange)
            }
        }
    }

    private var batchRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Batch Records")
                    .font(.headline.bold())
                Spacer()
                Text("VIEW ALL DOCUMENTATION")
                    .font(.caption.weight(.bold))
                    .kerning(0.8)
                    .foregroundColor(.hatchGreen)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                Image("egg_tray_photo") // Replace with actual image names
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
                
                Image("hand_holding_eggs")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
                
                Image("chicks_photo")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
                
                Image("notebook_photo")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
                
                Image("egg_tray_photo_2")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.hatchGreenSoft.opacity(0.5))
                    Image(systemName: "camera.viewfinder")
                        .font(.title)
                        .foregroundColor(.hatchGreen)
                }
                .frame(height: 120)
            }
        }
    }

    private var auditReportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image("supervisor_aris") // placeholder
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .background(Circle().fill(Color.gray.opacity(0.2)))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dr. Aris Thorne")
                        .font(.subheadline.weight(.bold))
                    Text("LEAD HATCHERY SUPERVISOR")
                        .font(.caption2.weight(.bold))
                        .kerning(0.5)
                        .foregroundColor(.secondary)
                }
            }

            Text("Batch #B2023-10-A exhibited exceptional uniformity during the transfer phase. Temperature stabilization was maintained within a 0.2° margin. We observed a minor fluctuation in humidity during the final 48 hours, but the 15% safety buffer successfully mitigated any risk to chick vitality. Recommend maintaining current sanitation protocols for the upcoming cycle.")
                .font(.subheadline)
                .italic()
                .foregroundColor(.black.opacity(0.7))
                .lineSpacing(4)

            Divider()

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.hatchGreen)
                    Text("VALIDATED REPORT")
                        .font(.caption2.weight(.bold))
                        .kerning(0.5)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("ID: 98033-ATH")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    // MARK: - Helper Views

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2.weight(.bold))
                .kerning(0.5)
                .foregroundColor(.secondary)
        }
    }

    private func chartBarGroup(label: String, standard: CGFloat, actual: CGFloat) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.hatchGreen.opacity(0.2))
                    .frame(width: 14, height: 100 * standard)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.hatchOrange)
                    .frame(width: 14, height: 100 * actual)
            }
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func statCard(title: String, value: String, subtitle: String, icon: String?, isPositive: Bool?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .kerning(0.5)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 26, weight: .bold))
            
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(isPositive == true ? .hatchGreen : .secondary)
                }
                Text(subtitle)
                    .font(.caption2.weight(.bold))
                    .kerning(0.5)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
    }

    private func flockRow(id: String, age: String, allocated: String, healthy: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .foregroundColor(.hatchGreen)
                .padding(12)
                .background(Circle().fill(Color.hatchGreenSoft))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(id)
                    .font(.headline.bold())
                Text(age)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(allocated)
                    .font(.headline.bold())
                Text("ALLOCATED")
                    .font(.caption2.weight(.bold))
                    .kerning(0.5)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(healthy)
                    .font(.headline.bold())
                    .foregroundColor(.hatchGreen)
                Text("HEALTHY")
                    .font(.caption2.weight(.bold))
                    .kerning(0.5)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70, alignment: .trailing)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
    }

    private func timelineCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.1)))
            
            Text(title)
                .font(.caption2.weight(.bold))
                .kerning(0.5)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.hatchGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        ManagerDetailedBatchHistoryView(batchID: "#B2023-10", breed: "Ross 308", date: "October 24, 2023", status: "COMPLETED", statusColor: .hatchGreen)
    }
}
