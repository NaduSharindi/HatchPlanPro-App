//
//  ManagerHatchDetailsView.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-13.
//

import SwiftUI

struct ManagerHatchDetailsView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    let batch: ScheduledBatch

    private var detail: HatchDetailSnapshot {
        session.detailSnapshot(for: batch)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard
                liveSensorsCard
                operationalTimelineCard
                sourceFlocksCard
                biologicalTimelineCard
                observationsCard
            }
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationTitle("Hatch Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            session.fetchHatchDetail(for: batch.batchID)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(detail.productionUnit)
                .font(.caption.weight(.bold))
                .kerning(1.1)
                .foregroundColor(.secondary)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.batchID)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.hatchGreen)
                    Text(detail.breed)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(detail.criticalStatus)
                    .font(.caption.weight(.bold))
                    .kerning(0.8)
                    .foregroundColor(.hatchGreen)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(hex: "#F4C542")))
            }

            ZStack(alignment: .bottomLeading) {
                Image(detail.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
                    .overlay(
                        LinearGradient(colors: [Color.black.opacity(0.05), Color.black.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(detail.incubationStage)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                            Text("\(batch.batchID) • \(batch.breed)")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                        }
                        .padding(18)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if detail.liveConnected {
                    Text("CONNECTED")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.hatchGreen)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(.white))
                        .padding(12)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var liveSensorsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Live Sensors")
                    .font(.headline.bold())
                    .foregroundColor(.hatchGreen)
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("CONNECTED")
                        .font(.caption.weight(.bold))
                        .kerning(0.8)
                        .foregroundColor(.hatchGreen)
                }
            }

            HStack(spacing: 12) {
                sensorCard(title: "TEMP", value: sensorValue(for: "TEMP"), unit: sensorUnit(for: "TEMP"), status: sensorStatus(for: "TEMP"), icon: sensorIcon(for: "TEMP"), tint: .hatchGreen)
                sensorCard(title: "HUMIDITY", value: sensorValue(for: "HUMIDITY"), unit: sensorUnit(for: "HUMIDITY"), status: sensorStatus(for: "HUMIDITY"), icon: sensorIcon(for: "HUMIDITY"), tint: Color(hex: "#B78900"))
            }

            HStack(spacing: 12) {
                metricCard(title: "EGGS TO SET", value: detail.eggsToSetLabel, caption: "Batch target capacity", tint: .hatchGreen)
                metricCard(title: "SHAVALS NEEDED", value: detail.shavalsNeededLabel, caption: "Estimated supply req.", tint: Color(hex: "#B78900"))
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("CO2 SATURATION")
                        .font(.caption.weight(.bold))
                        .kerning(1)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                HStack(alignment: .bottom, spacing: 4) {
                    Text(detail.co2Value)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.hatchGreen)
                    Text(detail.co2Unit)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    Spacer()
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(detail.co2Bars.indices, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color(hex: "#B9C9B3"))
                                .frame(width: 8, height: CGFloat(18 + (detail.co2Bars[index] * 38)))
                        }
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: "#FAFAFA")))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var operationalTimelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Operational Timeline")
                .font(.headline.bold())
                .foregroundColor(.hatchGreen)

            HStack(spacing: 12) {
                ForEach(detail.operationalTimeline) { tile in
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: tile.title.contains("EGG") ? "calendar.badge.plus" : "flame.fill")
                            .foregroundColor(tile.accentColor)
                            .padding(10)
                            .background(Circle().fill(tile.accentColor.opacity(0.12)))
                        Text(tile.title)
                            .font(.caption.weight(.bold))
                            .kerning(0.8)
                            .foregroundColor(.secondary)
                        Text(tile.value)
                            .font(.subheadline.bold())
                            .foregroundColor(.hatchGreen)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var sourceFlocksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Source Flocks")
                    .font(.headline.bold())
                    .foregroundColor(.hatchGreen)
                Spacer()
                Text("MULTI-BATCH ALLOCATION")
                    .font(.caption.weight(.bold))
                    .kerning(0.8)
                    .foregroundColor(.hatchGreen)
            }

            VStack(spacing: 12) {
                ForEach(detail.sourceFlocks) { flock in
                    HStack(spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(.hatchGreen)
                            .padding(10)
                            .background(Circle().fill(Color.hatchGreenSoft))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(flock.flockID)
                                .font(.headline)
                                .foregroundColor(.hatchGreen)
                            Text(flock.ageWeeks)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(flock.allocated)
                                .font(.headline.bold())
                                .foregroundColor(.hatchGreen)
                            Text(flock.statusLabel)
                                .font(.caption2.weight(.bold))
                                .kerning(0.8)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FAFAFA")))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var biologicalTimelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Biological Timeline")
                .font(.headline.bold())
                .foregroundColor(.hatchGreen)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(detail.biologicalTimeline.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(timelineColor(step.state))
                                .frame(width: 18, height: 18)
                                .overlay(Image(systemName: timelineIcon(step.state)).font(.caption2).foregroundColor(.white))
                            if index != detail.biologicalTimeline.count - 1 {
                                Rectangle()
                                    .fill(Color(hex: "#D8D8D8"))
                                    .frame(width: 2, height: 46)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(step.title)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.hatchGreen)
                                Spacer()
                                Text(step.timeLabel)
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(timelineColor(step.state))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Capsule().fill(timelineColor(step.state).opacity(0.12)))
                            }
                            Text(step.detail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: "#FAFAFA")))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var observationsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Supervisor Observations", systemImage: "note.text")
                    .font(.headline.bold())
                    .foregroundColor(.hatchGreen)
                Spacer()
                NavigationLink(destination: SupervisorObservationEditorView(batch: batch, existingObservation: detail.observations.first)) {
                    Text("EDIT")
                        .font(.caption.weight(.bold))
                        .kerning(0.8)
                        .foregroundColor(.white)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(Color.hatchGreen))
                }
                .buttonStyle(.plain)
            }

            ForEach(detail.observations) { observation in
                VStack(alignment: .leading, spacing: 12) {
                    Text(observation.note)
                        .font(.body)
                        .foregroundColor(.hatchGreen)

                    Text("ATTACHED PHOTOS (\(observation.attachedPhotos.count))")
                        .font(.caption.weight(.bold))
                        .kerning(0.8)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(observation.attachedPhotos, id: \.self) { photoName in
                                Image(photoName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 66, height: 66)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(hex: "#F0F0F0")))
                            }
                        }
                    }

                    NavigationLink(destination: SupervisorObservationEditorView(batch: batch, existingObservation: nil)) {
                        Label("Add New Observation", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.hatchGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#EAEAEA")))
                    }
                    .buttonStyle(.plain)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(observation.authorName)
                                .font(.caption.weight(.bold))
                                .foregroundColor(.hatchGreen)
                            Text(observation.authorRole)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(observation.timeLabel)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private func sensorCard(title: String, value: String, unit: String, status: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(tint)
                Spacer()
                Text(title)
                    .font(.caption.weight(.bold))
                    .kerning(0.8)
                    .foregroundColor(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.hatchGreen)
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            Text(status)
                .font(.caption2.weight(.bold))
                .kerning(0.8)
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: "#FAFAFA")))
    }

    private func metricCard(title: String, value: String, caption: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .kerning(0.8)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.hatchGreen)
            Text(caption)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(tint.opacity(0.08)))
    }

    private func sensorValue(for title: String) -> String {
        detail.sensors.first(where: { $0.title == title })?.value ?? "--"
    }

    private func sensorUnit(for title: String) -> String {
        detail.sensors.first(where: { $0.title == title })?.unit ?? ""
    }

    private func sensorStatus(for title: String) -> String {
        detail.sensors.first(where: { $0.title == title })?.status ?? ""
    }

    private func sensorIcon(for title: String) -> String {
        detail.sensors.first(where: { $0.title == title })?.iconName ?? "circle"
    }

    private func timelineColor(_ state: String) -> Color {
        switch state.lowercased() {
        case "completed":
            return .hatchGreen
        case "active":
            return Color(hex: "#F4C542")
        default:
            return Color(hex: "#BFBFBF")
        }
    }

    private func timelineIcon(_ state: String) -> String {
        switch state.lowercased() {
        case "completed":
            return "checkmark"
        case "active":
            return "flame.fill"
        default:
            return "clock.fill"
        }
    }
}

private extension HatchMetricTile {
    var accentColor: Color {
        Color(hex: accent)
    }
}

#Preview {
    NavigationStack {
        ManagerHatchDetailsView(batch: ScheduledBatch(batchID: "#B7-902", breed: "Ross 308", eggs: 12480, time: "08:45", timeOfDay: "AM", dateLabel: "TODAY, OCT 25", status: "CRITICAL", statusColor: Color(hex: "#F4C542")))
            .environmentObject(AppSessionViewModel())
    }
}
