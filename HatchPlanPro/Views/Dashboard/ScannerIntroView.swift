//
//  ScannerIntroView.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-13.
//

import SwiftUI

struct ScannerIntroView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: AppSessionViewModel
    @State private var targetChicks: String = ""
    @State private var showScanner = false

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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Hero Image
                        ZStack {
                            // Placeholder for hero image (user will add to Assets)
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.hatchSurface)
                                .frame(height: 200)
                            
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("Initialization Phase")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.hatchGreen)
                                    .padding(.top, 8)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.hatchGreenSoft, lineWidth: 2)
                        )
                        .padding(.horizontal, 16)
                        
                        // MARK: - Scan Certificate Option
                        VStack(spacing: 0) {
                            NavigationLink(destination: LiveScannerView()) {
                                HStack(spacing: 12) {
                                    // Green icon background
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.hatchGreen)
                                        
                                        Image(systemName: "doc.text.viewfinder")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 40, height: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Scan Verified Attached Certificate")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.black)
                                        
                                        Text("Capture data from official hatchery docs")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // MARK: - Production Targets
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRODUCTION TARGETS")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Target Chicks")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                HStack {
                                    TextField("e.g. 12,500", text: $targetChicks)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.black)
                                        .keyboardType(.numberPad)
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.hatchSurface)
                                .cornerRadius(8)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            
                            Text("Targets are used to calculate the required setter capacity and synchronization windows.")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                        }
                        
                        // MARK: - Supervisor Insight
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#FFA500").opacity(0.1))
                                    
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "#997700"))
                                }
                                .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Supervisor Insight")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.black)
                                    
                                    Text("Setting a batch with flock age over 45 weeks may require adjusted humidity levels in Stage 2.")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondary)
                                        .lineLimit(nil)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(hex: "#FFF9E6"))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    .padding(.vertical, 20)
                }
                
                Spacer()
                
                // MARK: - Continue Button
                NavigationLink(destination: LiveScannerView()) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
                }
                .padding(16)
                .padding(.bottom, 8)
            }
            .background(Color.hatchSurface)
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    ScannerIntroView()
        .environmentObject(AppSessionViewModel())
}
