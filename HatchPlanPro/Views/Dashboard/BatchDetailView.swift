//
//  BatchDetailView.swift
//  HatchPlanPro
//
//  Live view of a single batch. The bottom action changes with the
//  lifecycle state and the signed-in role.
//

import SwiftUI

struct BatchDetailView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @Environment(\.dismiss) private var dismiss

    let planID: String

    @State private var showExecuteSheet = false
    @State private var showClosing = false
    @State private var showRevision = false
    @State private var showReport = false
    @State private var showReview = false
    @State private var editingObservation: EditingObservation?
    @State private var fullScreenPhoto: PhotoViewer?
    @ObservedObject private var observationRepository = ObservationRepository.shared

    private var plan: HatchPlanRecord? { session.plan(withID: planID) }

    var body: some View {
        VStack(spacing: 0) {
            header

            if let plan {
                ScrollView {
                    VStack(spacing: 16) {
                        idCard(plan)
                        LifecycleProgressView(status: plan.status)
                            .padding(.horizontal, 4)
                        reviewCard(plan)
                        statGrid(plan)
                        timeline(plan)
                        sourceFlock(plan)
                        if let actual = plan.actualChicks { resultsCard(plan, actual: actual) }
                        if plan.status == .active || plan.status == .completed { biologicalTimeline(plan) }
                        observationsCard(plan)
                        SiteMapCard(site: plan.site)
                        CertificateRecordCard(plan: plan)
                    }
                    .padding(16)
                }
                actionBar(plan)
            } else {
                ContentUnavailableView("Batch Unavailable", systemImage: "tray",
                                       description: Text("This batch may have been removed on another device."))
            }
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showExecuteSheet) {
            ExecuteSetSheetView(planID: planID)
        }
        .navigationDestination(isPresented: $showClosing) { BatchClosingView(planID: planID) }
        .navigationDestination(isPresented: $showRevision) {
            if let plan { ScannerIntroView(revising: plan) }
        }
        .navigationDestination(isPresented: $showReport) { ManagerReportPreviewView(planID: planID) }
        .navigationDestination(isPresented: $showReview) { ManagerApprovalPlanView(planID: planID) }
        .navigationDestination(item: $editingObservation) { editing in
            ObservationEditorView(observation: editing.observation, isNew: editing.isNew)
        }
        .sheet(item: $fullScreenPhoto) { photo in
            if let image = UIImage(data: photo.data) {
                Image(uiImage: image).resizable().scaledToFit().padding()
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear { observationRepository.startListening(planID: planID) }
        .onDisappear { observationRepository.stopListening(planID: planID) }
    }

    private var header: some View {
        ScreenHeader(title: "Batch Details")
            .padding(.bottom, 4)
            .background(Color.hatchSurface)
    }

    // MARK: - Biological timeline

    private func biologicalTimeline(_ plan: HatchPlanRecord) -> some View {
        let day = plan.incubationDay()
        let steps: [(String, String, Int, Int)] = [
            ("Egg Setting", "Day 0: \(plan.requiredEggs.formatted()) eggs placed in setters.", 0, 0),
            ("Incubation Phase", "Days 1–\(ProductionCalculator.transferDay - 1): temperature and humidity cycling.", 1, ProductionCalculator.transferDay - 1),
            ("Transfer to Hatcher", "Day \(ProductionCalculator.transferDay): move \(plan.setterTrays) trays to hatcher baskets.",
             ProductionCalculator.transferDay, ProductionCalculator.incubationDays - 1),
            ("Final Hatch Completion", "Day \(ProductionCalculator.incubationDays): pulling and quality assessment.",
             ProductionCalculator.incubationDays, ProductionCalculator.incubationDays)
        ]

        func state(start: Int, end: Int) -> (label: String, color: Color, icon: String) {
            switch plan.status {
            case .completed:
                return ("COMPLETED", .hatchGreen, "checkmark.circle.fill")
            case .active where day > end || (start == 0 && end == 0):
                return ("COMPLETED", .hatchGreen, "checkmark.circle.fill")
            case .active where day >= start:
                return ("ACTIVE", .hatchOrange, "circle.dotted.circle.fill")
            default:
                return ("UPCOMING", .secondary, "clock")
            }
        }

        return VStack(alignment: .leading, spacing: 0) {
            Text("Biological Timeline").font(.headline).foregroundColor(.hatchGreen).padding(.bottom, 12)
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                let status = state(start: step.2, end: step.3)
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        Image(systemName: status.icon).foregroundColor(status.color).font(.title3)
                        if index < steps.count - 1 {
                            Rectangle().fill(Color.gray.opacity(0.25)).frame(width: 2).frame(minHeight: 34)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(step.0).font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(status.label)
                                .font(.caption2.weight(.bold))
                                .foregroundColor(status.color == .secondary ? .secondary : .white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(status.color == .secondary ? Color.gray.opacity(0.15) : status.color))
                        }
                        Text(step.1).font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.bottom, 14)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
    }

    // MARK: - Observations

    private func observationsCard(_ plan: HatchPlanRecord) -> some View {
        let observations = observationRepository.observations(for: plan.id)
        let canAdd = session.currentRole == .supervisor && plan.status != .completed && plan.status != .rejected

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Supervisor Observations", systemImage: "note.text")
                    .font(.headline)
                    .foregroundColor(.hatchGreen)
                Spacer()
                Text("\(observations.count)").font(.caption.weight(.bold)).foregroundColor(.secondary)
            }

            if observations.isEmpty {
                Text(canAdd ? "No observations yet. Record shell quality, egg vitality or temperature notes with photos."
                            : "No observations recorded for this batch.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ForEach(observations) { observation in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(observation.category.rawValue, systemImage: observation.category.icon)
                            .font(.caption.weight(.bold))
                            .foregroundColor(observation.category.accentColor)
                        Spacer()
                        if session.canEdit(observation) && plan.status != .completed {
                            Button("EDIT") { editingObservation = EditingObservation(observation: observation, isNew: false) }
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.hatchGreenDeep))
                        }
                    }
                    Text(observation.note).font(.subheadline)

                    if !observation.photos.isEmpty {
                        Text("ATTACHED PHOTOS (\(observation.photos.count))")
                            .font(.caption2.weight(.bold)).tracking(1).foregroundColor(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(observation.photos.enumerated()), id: \.offset) { _, data in
                                    if let image = UIImage(data: data) {
                                        Button(action: { fullScreenPhoto = PhotoViewer(data: data) }) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 84, height: 84)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        .accessibilityLabel("Observation photo")
                                    }
                                }
                            }
                        }
                    }

                    HStack {
                        Text(observation.authorName.isEmpty ? "Supervisor" : observation.authorName)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.hatchGreen)
                        Text(observation.authorRole).font(.caption2).foregroundColor(.secondary)
                        Spacer()
                        Text(observation.updatedAt.formatted(date: .abbreviated, time: .shortened) + (observation.wasEdited ? " • edited" : ""))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.hatchSurface))
            }

            if canAdd {
                Button(action: { editingObservation = EditingObservation(observation: session.newObservation(for: plan.id), isNew: true) }) {
                    Label("Add New Observation", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.hatchGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreenSoft))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
    }

    private func idCard(_ plan: HatchPlanRecord) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BATCH ID").font(.caption2.weight(.bold)).foregroundColor(.hatchOrange)
                Text(plan.batchID).font(.title.weight(.bold)).foregroundColor(.hatchGreen)
                Label(plan.site.name, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !plan.customerName.isEmpty {
                    Label(plan.customerName, systemImage: "cart")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                BatchStatusBadge(status: plan.status)
                Label(countdownText(plan), systemImage: "clock")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.hatchOrange)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
    }

    private func countdownText(_ plan: HatchPlanRecord) -> String {
        switch plan.status {
        case .active:
            let days = plan.daysUntilHatch()
            return days == 0 ? "Hatch day" : "Day \(plan.incubationDay()) • \(days) days left"
        case .completed:
            return "Closed \(plan.closedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")"
        default:
            return "Set \(plan.eggSetDate)"
        }
    }

    @ViewBuilder
    private func reviewCard(_ plan: HatchPlanRecord) -> some View {
        if plan.status == .rejected, let reason = plan.rejectionReason {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rejected by \(plan.reviewedBy ?? "manager")").font(.subheadline.weight(.semibold))
                    Text(reason).font(.subheadline)
                }
            } icon: {
                Image(systemName: "exclamationmark.circle.fill")
            }
            .foregroundColor(Color(hex: "#B3261E"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#FDECEA")))
        } else if let signature = plan.approvalSignature {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Digitally signed").font(.subheadline.weight(.semibold))
                    Text(signature).font(.caption).foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: "checkmark.seal.fill").foregroundColor(.hatchGreen)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.hatchGreenSoft))
        }
    }

    private func statGrid(_ plan: HatchPlanRecord) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
            BatchStatTile(title: "TARGET EGG SET", value: plan.requiredEggs.formatted(), icon: "list.clipboard")
            BatchStatTile(title: "SAFETY BUFFER", value: plan.safetyBuffer.formatted(.percent.precision(.fractionLength(1))), icon: "checkmark.shield", highlighted: true)
            BatchStatTile(title: "SETTER TRAYS", value: "\(plan.setterTrays) Units", icon: "tray.full")
            BatchStatTile(title: "TARGET CHICKS", value: plan.targetChicks.formatted(), icon: "bird")
        }
    }

    private func timeline(_ plan: HatchPlanRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OPERATIONAL TIMELINE").font(.caption.weight(.bold)).foregroundColor(.secondary)
            HStack(spacing: 12) {
                timelineTile("EGG SET DATE", plan.eggSetDate, icon: "calendar.badge.plus")
                timelineTile("TRANSFER", plan.transferDate.formatted(date: .abbreviated, time: .omitted), icon: "arrow.right.square")
                timelineTile("HATCH DATE", plan.hatchDate, icon: "oval.portrait.fill")
            }
            if plan.status == .active {
                ProgressView(value: plan.incubationProgress()) {
                    Text("Incubation day \(plan.incubationDay()) of \(ProductionCalculator.incubationDays)").font(.caption)
                }
                .tint(.hatchOrange)
            }
            if !plan.calendarEventIDs.isEmpty {
                Label("\(plan.calendarEventIDs.count) milestones in Calendar", systemImage: "calendar.badge.checkmark")
                    .font(.caption)
                    .foregroundColor(.hatchGreen)
            }
        }
    }

    private func timelineTile(_ title: String, _ value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundColor(.hatchGreen)
            Text(title).font(.caption2.weight(.semibold)).foregroundColor(.secondary)
            Text(value).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .accessibilityElement(children: .combine)
    }

    private func sourceFlock(_ plan: HatchPlanRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Source Flock").font(.headline)
                Spacer()
                Text(plan.breed.rawValue.uppercased()).font(.caption.weight(.bold)).foregroundColor(.hatchGreen)
            }
            HStack {
                Image(systemName: "leaf.circle.fill").font(.title2).foregroundColor(.hatchGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.flockID).font(.subheadline.weight(.semibold))
                    Text("\(plan.flockAgeWeeks) weeks • standard \(plan.standardHatchability.formatted(.percent.precision(.fractionLength(1))))")
                        .font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.requiredEggs.formatted()).font(.headline).foregroundColor(.hatchGreen)
                    Text("ALLOCATED").font(.caption2.weight(.bold)).foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        }
    }

    private func resultsCard(_ plan: HatchPlanRecord, actual: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YIELD SUMMARY").font(.caption.weight(.bold)).foregroundColor(Color(hex: "#7A5C00"))
            HStack(alignment: .lastTextBaseline) {
                Text(actual.formatted()).font(.system(size: 34, weight: .bold)).foregroundColor(Color(hex: "#7A5C00"))
                Text("chicks hatched").font(.caption).foregroundColor(Color(hex: "#7A5C00"))
                Spacer()
                if let rate = plan.actualHatchability {
                    Text(rate.formatted(.percent.precision(.fractionLength(1)))).font(.title3.weight(.bold))
                }
            }
            if let variance = plan.chickVariance, let hatchVariance = plan.hatchabilityVariance {
                HStack {
                    Text("vs order: \(variance >= 0 ? "+" : "")\(variance.formatted())")
                    Spacer()
                    Text("vs standard: \(hatchVariance >= 0 ? "+" : "")\(hatchVariance.formatted(.percent.precision(.fractionLength(1))))")
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(variance >= 0 ? .hatchGreen : Color(hex: "#B3261E"))
            }
            if let notes = plan.closingNotes, !notes.isEmpty {
                Text(notes).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: "#FFD966")))
    }

    @ViewBuilder
    private func actionBar(_ plan: HatchPlanRecord) -> some View {
        let isSupervisor = session.currentRole == .supervisor
        Group {
            switch plan.status {
            case .approvedReady where isSupervisor:
                actionButton("Execute Set", icon: "play.circle") { showExecuteSheet = true }
            case .active where isSupervisor:
                actionButton("Log Hatch Results", icon: "checkmark.circle") { showClosing = true }
            case .rejected where isSupervisor:
                actionButton("Revise & Resubmit", icon: "arrow.uturn.backward.circle") { showRevision = true }
            case .pendingReview where !isSupervisor:
                actionButton("Review Plan", icon: "checklist") { showReview = true }
            case .approvedReady, .active, .completed:
                actionButton(plan.status == .completed ? "View Performance Report" : "Generate PDF Report", icon: "doc.richtext") { showReport = true }
            default:
                EmptyView()
            }
        }
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
        }
        .padding(16)
        .background(Color.white)
    }
}

struct EditingObservation: Identifiable, Hashable {
    var id: String { observation.id }
    let observation: BatchObservation
    let isNew: Bool
}

struct PhotoViewer: Identifiable {
    let id = UUID()
    let data: Data
}

#Preview {
    NavigationStack {
        BatchDetailView(planID: "demo-B1028")
            .environmentObject(AppSessionViewModel())
    }
}
