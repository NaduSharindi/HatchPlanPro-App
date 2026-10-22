//
//  ScanResultView.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-13.
//

import SwiftUI

struct ScanResultView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: AppSessionViewModel
    let scanResult: VisionScanResult
    @State private var showBatchForm = false
    @State private var navigateToForm = false

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
                        // MARK: - Hero Card with Image
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
                        
                        // MARK: - Verified Certificate Badge
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.hatchGreen.opacity(0.1))
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.hatchGreen)
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Verified Certificate Attached")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                HStack(spacing: 8) {
                                    Text("Confidence:")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondary)
                                    
                                    Text(String(format: "%.1f%%", scanResult.confidence * 100))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.hatchGreen)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.hatchGreenSoft)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        
                        // MARK: - Vital Statistics
                        VStack(alignment: .leading, spacing: 12) {
                            Text("VITAL STATISTICS")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            // Target Chicks
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Target Chicks")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text("12500")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.hatchGreen)
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
                            
                            HStack(spacing: 16) {
                                // Egg Set Date
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 14))
                                            .foregroundColor(.hatchGreen)
                                        
                                        Text("EGG SET DATE")
                                            .font(.system(size: 11, weight: .semibold))
                                            .tracking(0.5)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("Oct 20, 2023")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                
                                // Hatch Date
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 14))
                                            .foregroundColor(.hatchOrange)
                                        
                                        Text("HATCH DATE")
                                            .font(.system(size: 11, weight: .semibold))
                                            .tracking(0.5)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("Nov 10, 2023")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // MARK: - Digital Intake
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DIGITAL INTAKE")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Flock ID")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(scanResult.flockID ?? "---")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.hatchGreen)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Scan Date")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(scanResult.scanDate ?? "---")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.hatchGreen)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Fields Found")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(scanResult.fieldsFound)/05")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.hatchGreen)
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                        
                        // Spacing
                        Spacer()
                            .frame(height: 20)
                    }
                }
                
                Spacer()
                
                // MARK: - Action Buttons
                VStack(spacing: 12) {
                    NavigationLink(destination: BatchFormFromScanView(scanResult: scanResult)) {
                        Text("Send for Approval")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Retake")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.hatchGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color.hatchGreen, lineWidth: 1.5))
                    }
                }
                .padding(16)
                
                // Allocation Summary label
                Text("Allocation Summary")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            .background(Color.hatchSurface)
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    ScanResultView(
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
