//
//  BatchDetailView.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-13.
//

import SwiftUI
import MapKit

struct BatchDetailView: View {
    @EnvironmentObject var session: AppSessionViewModel
    @Environment(\.dismiss) var dismiss

    let batchID: String
    let breed: String
    let date: String
    let status: String
    let statusColor: Color
    let canExecute: Bool

    @State private var showExecuteSheet = false
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 6.9319, longitude: 79.8478), span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06))

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.hatchGreen)
                }
                Spacer()
                Text("Batch Details")
                    .font(.headline)
                    .foregroundColor(.hatchGreen)
                Spacer()
                Button(action: { /* maybe open more */ }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // ID Card
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("BATCH ID")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.secondary)
                            Text(batchID)
                                .font(.title3.weight(.bold))
                                .foregroundColor(.hatchGreen)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(status)
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(statusColor))
                            
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .foregroundColor(.hatchGreen)
                                Text("4 Days Left")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))

                    // Stat tiles
                    HStack(spacing: 12) {
                        statTile(title: "TARGET EGG SET", value: "14,500", icon: "cube.box.fill")
                        statTile(title: "SAFETY BUFFER", value: "15%", icon: "shield.fill", bg: Color(hex: "#F7E7B6"))
                    }
                    .padding(.horizontal, 16)

                    HStack(spacing: 12) {
                        statTile(title: "SHAVALS REQUIRED", value: "450 Units", icon: "tray.full")
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    // Timeline
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OPERATIONAL TIMELINE")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            timelineTile(title: "EGG SET DATE", value: "Oct 20, 2023", icon: "calendar")
                            timelineTile(title: "HATCH DATE", value: "Nov 10, 2023", icon: "oval.portrait.fill")
                        }
                    }
                    .padding(.horizontal, 16)

                    // Source flocks
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Source Flocks")
                                .font(.headline)
                                .foregroundColor(.hatchGreen)
                            Spacer()
                            Text("MULTI-BATCH ALLOCATION")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        VStack(spacing: 12) {
                            sourceRow(id: "F-902", weeks: "34 weeks", allocated: "6,000")
                            sourceRow(id: "F-815", weeks: "26 weeks", allocated: "4,500")
                            sourceRow(id: "F-722", weeks: "34 weeks", allocated: "4,000")
                        }
                    }
                    .padding(.horizontal, 16)

                    // Map card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Station C-9")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        Text("Hatchery Main Sector")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .background(
                        Map(coordinateRegion: $region, interactionModes: .all, annotationItems: [MapPin(coordinate: region.center)]) { pin in
                            MapMarker(coordinate: pin.coordinate, tint: .hatchGreen)
                        }
                        .cornerRadius(12)
                    )
                    .padding(.horizontal, 16)

                    // Batch Records grid (placeholders)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Batch Records")
                                .font(.headline)
                                .foregroundColor(.hatchGreen)
                            Spacer()
                            Text("View All (9)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                            ForEach(0..<6) { idx in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#F7F7FA"))
                                    .frame(height: 74)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 40)
                }
            }

            if canExecute {
                Button(action: { showExecuteSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                        Text("Execute Set")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
                    .padding(16)
                }
                .sheet(isPresented: $showExecuteSheet) {
                    ExecuteSetSheetView(batchID: batchID)
                        .environmentObject(session)
                }
            }
        }
        .background(Color.hatchSurface.ignoresSafeArea())
    }

    private func statTile(title: String, value: String, icon: String, bg: Color = Color.white) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.hatchGreen)
                    .padding(8)
                    .background(Circle().fill(Color.hatchGreenSoft))
                Spacer()
            }
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.black)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(bg))
    }

    private func timelineTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.hatchGreen)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundColor(.black)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .frame(maxWidth: .infinity)
    }

    private func sourceRow(id: String, weeks: String, allocated: String) -> some View {
        HStack {
            Circle()
                .fill(Color.hatchGreenSoft)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "leaf.fill").foregroundColor(.hatchGreen))
            VStack(alignment: .leading, spacing: 4) {
                Text(id)
                    .font(.subheadline.weight(.semibold))
                Text(weeks)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(allocated)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.hatchGreen)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
    }
}

struct MapPin: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

#Preview {
    BatchDetailView(batchID: "#B1024", breed: "Ross 308", date: "Oct 24, 2023", status: "APPROVED", statusColor: .hatchGreen, canExecute: true)
        .environmentObject(AppSessionViewModel())
}
