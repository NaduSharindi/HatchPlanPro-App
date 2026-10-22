import SwiftUI

struct ManagerReportPreviewView: View {
    @Environment(\.dismiss) var dismiss
    
    // Using a simple URL for the ShareLink, but in a real app this would be the actual generated PDF file URL.
    let reportURL = URL(string: "https://example.com/Performance_Report_B1024.pdf")!
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }
                Spacer()
                Text("Report Preview")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.hatchGreen)
                Spacer()
                
                ShareLink(item: reportURL) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.hatchGreen)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .background(Color.white)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Logo and Status
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.hatchGreen)
                                Text("HatchPlan Pro")
                                    .font(.headline.weight(.bold))
                            }
                            Text("INDUSTRIAL\nPRECISION")
                                .font(.caption2.weight(.bold))
                                .kerning(1)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("DOCUMENT\nSTATUS")
                                .font(.caption2.weight(.bold))
                                .kerning(1)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                            Text("VERIFIED\nTRACEABILITY")
                                .font(.caption2.weight(.bold))
                                .kerning(0.5)
                                .foregroundColor(.hatchGreen)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Capsule().fill(Color.hatchGreen.opacity(0.3)))
                        }
                    }
                    
                    // Title
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Traceability\nSummary for\nOrder #B1024")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                            .lineSpacing(2)
                        
                        Text("Complete industrial lifecycle report detailing egg reception, incubation cycles, and projected hatch outcomes for facility Delta-9.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.leading, 16)
                    .overlay(
                        Rectangle()
                            .fill(Color.hatchGreen)
                            .frame(width: 4)
                        , alignment: .leading
                    )
                    
                    // Core Performance Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CORE PERFORMANCE")
                            .font(.caption2.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("94.2%")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.hatchGreen)
                            
                            Text("HATCH\nRATE")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.hatchGreen)
                        }
                        
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.gray.opacity(0.2)).frame(height: 8)
                            Capsule().fill(Color.hatchGreen).frame(width: UIScreen.main.bounds.width * 0.7, height: 8)
                        }
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#F5F5F7")))
                    
                    // Critical Buffer Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CRITICAL BUFFER")
                            .font(.caption2.weight(.bold))
                            .kerning(1)
                            .foregroundColor(Color(hex: "#8B6B23"))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("15%")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(Color(hex: "#8B6B23"))
                            
                            Text("SAFETY\nMARGIN")
                                .font(.caption.weight(.bold))
                                .foregroundColor(Color(hex: "#8B6B23"))
                        }
                        
                        Text("Calculated biological variance protection applied to Harvest Gold standard timeline.")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#8B6B23").opacity(0.8))
                            .lineSpacing(2)
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#FFF9E6")))
                    
                    // Chart Section
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hatchability")
                                    .font(.headline.weight(.bold))
                                Text("vs. Standard")
                                    .font(.headline.weight(.bold))
                            }
                            Spacer()
                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Capsule().fill(Color.hatchGreen).frame(width: 8, height: 16)
                                    Text("BATCH\n#B1024")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(.secondary)
                                }
                                HStack(spacing: 4) {
                                    Capsule().fill(Color.gray.opacity(0.4)).frame(width: 8, height: 16)
                                    Text("INDUSTRY\nSTANDARD")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        HStack(alignment: .bottom, spacing: 30) {
                            chartColumn(day: "DAY 7", value: "85%", standardHeight: 0.6, batchHeight: 0.7)
                            chartColumn(day: "DAY 14", value: "92%", standardHeight: 0.5, batchHeight: 0.8)
                            chartColumn(day: "DAY 21", value: "94%", standardHeight: 0.5, batchHeight: 0.85)
                        }
                        .frame(height: 200)
                        
                        Divider()
                    }
                }
                .padding(24)
                .background(Color.white)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .overlay(alignment: .bottomTrailing) {
            ShareLink(item: reportURL) {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.black)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color(hex: "#FDD835")))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
            }
            .padding(24)
        }
    }
    
    private func chartColumn(day: String, value: String, standardHeight: CGFloat, batchHeight: CGFloat) -> some View {
        VStack(spacing: 12) {
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundColor(.hatchGreen)
            
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 44, height: 140 * standardHeight)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.hatchGreen)
                    .frame(width: 44, height: 140 * batchHeight)
            }
            
            Text(day)
                .font(.caption2.weight(.bold))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ManagerReportPreviewView()
}
