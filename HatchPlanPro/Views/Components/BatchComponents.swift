//
//  BatchComponents.swift
//  HatchPlanPro
//
//  Building blocks shared by the supervisor and manager batch screens.
//

import SwiftUI
import MapKit

struct BatchStatusBadge: View {
    let status: BatchStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2.weight(.bold))
            .kerning(0.6)
            .foregroundColor(status == .pendingReview ? .black.opacity(0.75) : .white)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(Capsule().fill(status == .pendingReview ? Color(hex: "#FFD966") : status.color))
            .accessibilityLabel("Status: \(status.displayName.lowercased())")
    }
}

struct BatchStatTile: View {
    let title: String
    let value: String
    let icon: String
    var highlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(highlighted ? Color(hex: "#7A5C00") : .hatchGreen)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(highlighted ? Color(hex: "#7A5C00") : .secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(highlighted ? Color(hex: "#7A5C00") : .primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(highlighted ? Color(hex: "#FFD966") : .white))
        .accessibilityElement(children: .combine)
    }
}

struct SiteMapCard: View {
    let site: HatcherySite
    var height: CGFloat = 150

    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(center: site.coordinate,
                                                         span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))) {
            Marker(site.name, systemImage: "building.2.fill", coordinate: site.coordinate)
                .tint(Color.hatchGreen)
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .allowsHitTesting(false)
        .frame(height: height)
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill").foregroundColor(.white)
                VStack(alignment: .leading, spacing: 1) {
                    Text(site.name).font(.subheadline.weight(.semibold))
                    Text(site.sector).font(.caption2)
                }
                .foregroundColor(.white)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.45)))
            .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Map of \(site.name), \(site.sector)")
    }
}

struct CertificateRecordCard: View {
    let plan: HatchPlanRecord
    @State private var showFullImage = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Batch Records")
                    .font(.headline)
                    .foregroundColor(.hatchGreen)
                Spacer()
                if let confidence = plan.ocrConfidence {
                    Text("OCR \(confidence.formatted(.percent.precision(.fractionLength(0))))")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                }
            }

            if let data = plan.certificateImage, let image = UIImage(data: data) {
                Button(action: { showFullImage = true }) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Flock health certificate scan. Double tap to enlarge.")
                .sheet(isPresented: $showFullImage) {
                    ScrollView([.horizontal, .vertical]) {
                        Image(uiImage: image).resizable().scaledToFit()
                    }
                    .presentationDragIndicator(.visible)
                }
            } else {
                Label("No certificate image attached", systemImage: "doc.badge.ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let text = plan.certificateText, !text.isEmpty {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.hatchSurface))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
    }
}

struct CalculationBreakdownCard: View {
    let plan: HatchPlanRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mathematical Breakdown")
                .font(.headline)
                .foregroundColor(.hatchGreen)
            step("Target chicks", plan.targetChicks.formatted())
            step("÷ Standard hatchability", plan.standardHatchability.formatted(.percent.precision(.fractionLength(1))),
                 detail: "\(plan.breed.rawValue), \(plan.flockAgeWeeks)-week flock")
            step("× (1 + safety buffer)", "1 + " + plan.safetyBuffer.formatted(.percent.precision(.fractionLength(1))))
            Divider()
            step("= Eggs to set", plan.requiredEggs.formatted(), emphasis: true)
            step("÷ \(ProductionCalculator.eggsPerSetterTray) eggs per tray", "\(plan.setterTrays.formatted()) trays")
            step("Site setter load", (Double(plan.requiredEggs) / Double(plan.site.setterCapacity)).formatted(.percent.precision(.fractionLength(0))),
                 detail: "of \(plan.site.setterCapacity.formatted()) capacity")
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
    }

    private func step(_ title: String, _ value: String, detail: String? = nil, emphasis: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline)
                if let detail { Text(detail).font(.caption2).foregroundColor(.secondary) }
            }
            Spacer()
            Text(value)
                .font(emphasis ? .title3.weight(.bold) : .subheadline.weight(.semibold))
                .foregroundColor(emphasis ? .hatchGreen : .primary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct LifecycleProgressView: View {
    let status: BatchStatus

    private let steps: [(String, BatchStatus)] = [
        ("Plan", .draft), ("Verify", .pendingReview), ("Approved", .approvedReady), ("Set", .active), ("Closed", .completed)
    ]

    private var reachedIndex: Int {
        switch status {
        case .draft: return 0
        case .pendingReview, .rejected: return 1
        case .approvedReady: return 2
        case .active: return 3
        case .completed: return 4
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                VStack(spacing: 6) {
                    Capsule()
                        .fill(index <= reachedIndex ? (status == .rejected && index == 1 ? Color(hex: "#FF6B6B") : Color.hatchGreen) : Color.gray.opacity(0.2))
                        .frame(height: 6)
                    Text(step.0)
                        .font(.caption2.weight(index == reachedIndex ? .bold : .regular))
                        .foregroundColor(index <= reachedIndex ? .primary : .secondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lifecycle stage \(reachedIndex + 1) of \(steps.count): \(steps[reachedIndex].0)")
    }
}
