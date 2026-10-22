//
//  ManagerTasksView.swift
//  HatchPlanPro
//
//  Geospatial verification: every Prima site on one map with its pending and
//  incubating load, and an approval card for the selected site's queue.
//

import SwiftUI
import MapKit

struct ManagerMapView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.83, longitude: 80.10),
        span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)))
    @State private var selectedSiteID: String?
    @State private var reviewPlanID: String?
    @State private var rejectingPlan: HatchPlanRecord?
    @State private var isSigning = false
    @State private var errorMessage: String?

    private var selectedSite: HatcherySite? { selectedSiteID.map { HatcherySite.site(withID: $0) } }

    private func pending(at site: HatcherySite) -> [HatchPlanRecord] {
        session.pendingPlans.filter { $0.siteID == site.id }
    }

    private func incubating(at site: HatcherySite) -> [HatchPlanRecord] {
        session.activePlans.filter { $0.siteID == site.id }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position, selection: $selectedSiteID) {
                ForEach(HatcherySite.all) { site in
                    Annotation(site.name, coordinate: site.coordinate) {
                        siteMarker(site)
                    }
                    .tag(site.id)
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }

            if let site = selectedSite {
                siteCard(site)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Text("Tap a site to review its plans")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .padding(.bottom, 20)
            }
        }
        .animation(.spring(duration: 0.3), value: selectedSiteID)
        .safeAreaInset(edge: .top) { header }
        .navigationBarHidden(true)
        .onAppear {
            if selectedSiteID == nil {
                selectedSiteID = session.pendingPlans.first?.siteID
            }
        }
        .navigationDestination(item: $reviewPlanID) { id in
            ManagerApprovalPlanView(planID: id)
        }
        .sheet(item: $rejectingPlan) { plan in
            RejectPlanSheet(batchID: plan.batchID) { reason in
                do {
                    try session.rejectPlan(planID: plan.id, reason: reason)
                    rejectingPlan = nil
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .alert("Action Not Applied", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            AppLogoView(size: 28)
            Text("HatchPlan Pro")
                .font(.headline.weight(.bold))
                .foregroundColor(.hatchGreen)
            Spacer()
            Label("\(session.pendingPlans.count) pending", systemImage: "clock.badge.exclamationmark")
                .font(.caption.weight(.bold))
                .foregroundColor(.hatchOrange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func siteMarker(_ site: HatcherySite) -> some View {
        let pendingCount = pending(at: site).count
        let selected = selectedSiteID == site.id
        return VStack(spacing: 2) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: selected ? 20 : 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: selected ? 44 : 36, height: selected ? 44 : 36)
                    .background(Circle().fill(Color.hatchGreen))
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                if pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.black)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color(hex: "#FFD966")))
                        .offset(x: 6, y: -6)
                }
            }
        }
        .accessibilityLabel("\(site.name), \(pendingCount) pending, \(incubating(at: site).count) incubating")
    }

    @ViewBuilder
    private func siteCard(_ site: HatcherySite) -> some View {
        let queue = pending(at: site)
        let active = incubating(at: site)
        let committedEggs = active.reduce(0) { $0 + $1.requiredEggs }

        VStack(alignment: .leading, spacing: 14) {
            Capsule().fill(Color.gray.opacity(0.4)).frame(width: 40, height: 5).frame(maxWidth: .infinity)

            if let plan = queue.first {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("APPROVAL PENDING").font(.caption2.weight(.bold)).kerning(1).foregroundColor(.hatchGreen)
                        Text("Plan Review: \(plan.batchID), \(site.name.replacingOccurrences(of: " Prima Farm", with: ""))")
                            .font(.title3.weight(.bold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("TARGET CHICKS").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                        Text(plan.targetChicks.formatted()).font(.headline).foregroundColor(.hatchGreen)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.hatchSurface))
                }

                HStack(spacing: 12) {
                    BatchStatTile(title: "SETTER TRAYS NEEDED", value: plan.setterTrays.formatted(), icon: "tray.full")
                    BatchStatTile(title: "BUFFER APPLIED", value: plan.safetyBuffer.formatted(.percent.precision(.fractionLength(1))), icon: "chart.bar.fill", highlighted: true)
                }

                let load = Double(committedEggs + plan.requiredEggs) / Double(site.setterCapacity)
                ProgressView(value: min(load, 1)) {
                    Text("Setter load if approved: \(load.formatted(.percent.precision(.fractionLength(0)))) (\(active.count) batch\(active.count == 1 ? "" : "es") incubating)")
                        .font(.caption)
                        .foregroundColor(load > 1 ? .red : .secondary)
                }
                .tint(load > 1 ? .red : .hatchGreen)

                Button("View Plan Details ›") { reviewPlanID = plan.id }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.hatchGreen)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 12) {
                    Button(action: { rejectingPlan = plan }) {
                        Label("Reject", systemImage: "xmark")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3)))
                    }
                    Button(action: { approve(plan) }) {
                        HStack {
                            if isSigning { ProgressView().tint(.white) } else { Image(systemName: "checkmark.circle.fill") }
                            Text("Approve")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreenDeep))
                    }
                    .disabled(isSigning)
                }

                if queue.count > 1 {
                    Text("+\(queue.count - 1) more pending at this site")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            } else {
                Text(site.name).font(.title3.weight(.bold))
                Text(site.sector).font(.subheadline).foregroundColor(.secondary)
                HStack(spacing: 12) {
                    BatchStatTile(title: "INCUBATING", value: "\(active.count) batches", icon: "thermometer.medium")
                    BatchStatTile(title: "SETTER LOAD", value: (Double(committedEggs) / Double(site.setterCapacity)).formatted(.percent.precision(.fractionLength(0))), icon: "gauge.with.dots.needle.33percent")
                }
                Label("No plans awaiting approval", systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundColor(.hatchGreen)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.regularMaterial))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private func approve(_ plan: HatchPlanRecord) {
        isSigning = true
        Task {
            do {
                try await session.approvePlan(planID: plan.id)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSigning = false
        }
    }
}
