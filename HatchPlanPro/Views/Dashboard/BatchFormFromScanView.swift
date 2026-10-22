

//
//  BatchFormFromScanView.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-13.
//

import SwiftUI

struct BatchFormFromScanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: AppSessionViewModel
    let scanResult: VisionScanResult
    @State private var showSuccessScreen = false
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.hatchGreen)
                    }
                    
                    Spacer()
                    
                    Text("New Plan")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.hatchGreen)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Hero Image
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.hatchOrangeSoft)
                            
                            VStack {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.hatchOrange)
                                
                                Text("Flock Parameters")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.top, 12)
                            }
                        }
                        .frame(height: 180)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        
                        // MARK: - Digital Intake Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DIGITAL INTAKE")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.hatchGreen.opacity(0.1))
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(Color.hatchGreen)
                                )
                                
                                Text("Verified Certificate Attached")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.hatchGreenSoft)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                        
                        // MARK: - Vital Statistics
                        VStack(alignment: .leading, spacing: 12) {
                            Text("VITAL STATISTICS")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Target Chicks")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("12500")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.hatchGreen)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Expected Yield")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("12,200 - 12,350")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.hatchGreen)
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                        
                        // MARK: - Operational Timeline
                        VStack(alignment: .leading, spacing: 12) {
                            Text("OPERATIONAL TIMELINE")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            HStack(spacing: 12) {
                                // Egg Set Date
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 12))
                                            .foregroundColor(.hatchGreen)
                                        
                                        Text("EGG SET")
                                            .font(.system(size: 10, weight: .semibold))
                                            .tracking(0.5)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("Oct 20, 2023")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                
                                // Hatch Date
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 12))
                                            .foregroundColor(.hatchOrange)
                                        
                                        Text("HATCH DATE")
                                            .font(.system(size: 10, weight: .semibold))
                                            .tracking(0.5)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("Nov 10, 2023")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // MARK: - Allocation Summary
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("ALLOCATION SUMMARY")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(0.5)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("OPTIMIZED")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(0.5)
                                    .foregroundColor(.hatchGreen)
                            }
                            .padding(.horizontal, 16)
                            
                            // Batch allocations
                            VStack(spacing: 12) {
                                AllocationItem(batchID: "B102", weeks: "34 weeks", units: "5,000", percentage: "40%")
                                AllocationItem(batchID: "B105", weeks: "34 weeks", units: "4,375", percentage: "35%")
                                AllocationItem(batchID: "B109", weeks: "34 weeks", units: "3,125", percentage: "25%")
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            
                            // Total row
                            HStack {
                                Text("TOTAL ALLOCATION")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("14,500 units")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .padding(12)
                            .background(Color.hatchSurface)
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                        }
                        
                        // MARK: - Biological Margin
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BIOLOGICAL MARGIN")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            HStack(spacing: 12) {
                                Text("Safety Buffer")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Text("4.5")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.hatchOrange)
                                    
                                    Text("%")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.hatchOrange)
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            
                            // Safety buffer slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("0% MIN")
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("10% MAX")
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: .constant(0.45))
                                    .tint(.hatchOrange)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            
                            // Info box
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#997700"))
                                
                                Text("Setting a 4.5% buffer compensates for standard biological variance in flock viability across transport.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                            }
                            .padding(12)
                            .background(Color(hex: "#FFF9E6"))
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - Send for Approval Button
                VStack(spacing: 12) {
                    Button(action: {
                        isSubmitting = true
                        submitBatchForApproval()
                    }) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send for Approval")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
                    .disabled(isSubmitting)
                }
                .padding(16)
            }
            .background(Color.hatchSurface)
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showSuccessScreen) {
                ApprovalConfirmationView()
                    .environmentObject(session)
            }
        }
    }
    
    private func submitBatchForApproval() {
        // Create scanned batch and save to Firebase
        let scannedBatch = ScannedBatch(
            batchID: scanResult.flockID ?? "B-\(UUID().uuidString.prefix(6))",
            breed: "Cobb 500",
            eggs: 14500,
            targetChicks: 12500,
            eggSetDate: "Oct 20, 2023",
            hatchDate: "Nov 10, 2023",
            status: .pendingReview,
            scanResult: scanResult,
            createdAt: Date(),
            createdBy: session.currentUser.fullName
        )
        
        // Save to session and Firebase
        session.saveScannedBatch(scannedBatch)
        
        // Show success screen after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            showSuccessScreen = true
        }
    }
}

// MARK: - Allocation Item Component
struct AllocationItem: View {
    let batchID: String
    let weeks: String
    let units: String
    let percentage: String

    private var filledSegments: Int {
        let percentValue = Int(percentage.replacingOccurrences(of: "%", with: "")) ?? 0
        return max(0, min(20, percentValue / 5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.hatchGreen)
                    
                    Text(batchID)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(units)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(percentage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.hatchGreen)
                }
            }
            
            HStack {
                Text(weeks)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<filledSegments, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.hatchGreen)
                            .frame(height: 4)
                    }
                    
                    ForEach(0..<(20 - filledSegments), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.hatchSurface)
                            .frame(height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}

// MARK: - Approval Confirmation View
struct ApprovalConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: AppSessionViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success checkmark
            ZStack {
                Circle()
                    .fill(Color.hatchGreen.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.hatchGreen)
            }
            
            // Title and message
            VStack(spacing: 12) {
                Text("Request Sent to Manager")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Your multi-batch plan for 12,500 units has been submitted for final review by Manager Aruni.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Details card
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RECIPIENT")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.secondary)
                    
                    Text("Manager Aruni")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("SENT")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.secondary)
                    
                    Text("Today, \(DateFormatter.timeFormatter.string(from: Date()))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("BATCHES")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(["#B102", "#B105", "#B109"], id: \.self) { batchID in
                            Text(batchID)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.hatchGreen)
                                .cornerRadius(6)
                        }
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color.hatchSurface)
            .cornerRadius(12)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Return to Dashboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
            }
        }
        .padding(24)
        .background(Color.white)
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    BatchFormFromScanView(
        scanResult: VisionScanResult(
            flockID: "298-AXB",
            scanDate: "24/OCT/23",
            confidence: 0.894,
            fieldsFound: 3,
            rawText: "FLOCK ID: 298-AXB\nDATE: 24/OCT/23",
            timestamp: Date()
        )
    )
    .environmentObject(AppSessionViewModel())
}
