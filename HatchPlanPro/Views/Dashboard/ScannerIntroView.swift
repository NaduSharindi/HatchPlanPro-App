//
//  ScannerIntroView.swift
//  HatchPlanPro
//
//  Supervisor "New Plan" screen: VisionKit certificate capture, flock
//  parameters, and the Smart Calculation Engine's live breakdown.
//

import SwiftUI
import PhotosUI

struct ScannerIntroView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel: NewPlanViewModel

    @State private var showDocumentScanner = false
    @State private var showPhotoPicker = false
    @State private var showScanSourceChoice = false
    @State private var showCameraUnavailable = false
    @State private var photoSelection: PhotosPickerItem?
    @State private var submittedPlan: HatchPlanRecord?
    @State private var submitError: String?
    @FocusState private var focusedField: Field?

    private enum Field { case batchID, flockID, customer, target }

    init(revising plan: HatchPlanRecord? = nil) {
        _viewModel = StateObject(wrappedValue: NewPlanViewModel(revising: plan))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    certificateSection
                    flockSection
                    targetSection
                    timelineSection
                    bufferSection
                    calculationSection
                    insightsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .scrollDismissesKeyboard(.interactively)

            submitBar
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .onAppear {
            if viewModel.batchID.isEmpty {
                viewModel.batchID = session.nextBatchID()
                if !viewModel.isRevision { viewModel.siteID = session.currentUser.siteID }
            }
        }
        .fullScreenCover(isPresented: $showDocumentScanner) {
            DocumentScannerView(
                onScan: { pages in
                    showDocumentScanner = false
                    Task { await viewModel.processScan(pages: pages) }
                },
                onCancel: { showDocumentScanner = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showScanSourceChoice) {
            ScanSourceSheet(
                cameraAvailable: cameraAvailable,
                onCamera: {
                    showScanSourceChoice = false
                    // Let the sheet finish dismissing before presenting the next one.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { scanWithCamera() }
                },
                onPhotos: {
                    showScanSourceChoice = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showPhotoPicker = true }
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .alert("Camera Unavailable", isPresented: $showCameraUnavailable) {
            Button("Choose from Photos") { showPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The document camera needs a physical iPhone or iPad. On the Simulator, choose a photo of the certificate instead.")
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoSelection, matching: .images)
        .onChange(of: photoSelection) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    await viewModel.processScan(pages: [image])
                }
                photoSelection = nil
            }
        }
        .fullScreenCover(item: $submittedPlan, onDismiss: { dismiss() }) { plan in
            PlanSubmittedView(plan: plan)
        }
        .alert("Unable to Submit", isPresented: Binding(get: { submitError != nil }, set: { if !$0 { submitError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(submitError ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.hatchGreen)
            }
            .accessibilityLabel("Back")

            Spacer()

            Text(viewModel.isRevision ? "Revise Plan" : "New Plan")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.hatchGreen)

            Spacer()

            Button("Cancel") { dismiss() }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [.hatchGreenDeep, .hatchGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "bird.fill")
                .font(.system(size: 110))
                .foregroundColor(.white.opacity(0.08))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(16)
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.isRevision ? "REVISION" : "PLANNING STAGE")
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundColor(.hatchGreenDeep)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: "#FFD966")))
                Text("Initialization Phase")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
            }
            .padding(18)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Certificate (Documentation)

    private var certificateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("DIGITAL INTAKE")

            Button(action: startScan) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(viewModel.hasCertificate ? Color(hex: "#1FA971") : .hatchGreen)
                        if viewModel.isProcessingScan {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: viewModel.hasCertificate ? "checkmark" : "doc.text.viewfinder")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.hasCertificate ? "Verified Certificate Attached" : "Scan Verified Attached Certificate")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(certificateSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: viewModel.hasCertificate ? "arrow.clockwise" : "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(viewModel.hasCertificate ? Color(hex: "#EAFBF3") : .white))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isProcessingScan)
            .accessibilityHint("Opens the document camera to read the batch ID, flock ID and flock age.")

            if let scan = viewModel.scan {
                HStack(spacing: 10) {
                    scanStat("CONFIDENCE", scan.confidence.formatted(.percent.precision(.fractionLength(1))))
                    scanStat("FIELDS FOUND", "\(scan.fields.fieldsFound)/\(CertificateFields.totalFields)")
                }
            }

            if let error = viewModel.scanError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#9A6B00"))
            }
        }
    }

    private var certificateSubtitle: String {
        if viewModel.isProcessingScan { return "Reading certificate…" }
        if viewModel.hasCertificate { return "Tap to rescan. Fields below were filled from the scan." }
        return "Scan with camera or choose a photo"
    }

    /// The Simulator reports VisionKit as supported but has no camera, so it
    /// always goes to the photo library.
    private var cameraAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return DocumentScannerView.isSupported
        #endif
    }

    private func startScan() {
        showScanSourceChoice = true
    }

    private func scanWithCamera() {
        if cameraAvailable {
            showDocumentScanner = true
        } else {
            showCameraUnavailable = true
        }
    }

    private func scanStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2.weight(.bold)).foregroundColor(.secondary)
            Text(value).font(.headline).foregroundColor(.hatchGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Flock Parameters

    private var flockSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("FLOCK PARAMETERS")
            VStack(spacing: 0) {
                formRow("Batch ID") {
                    TextField("#B1024", text: $viewModel.batchID)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .batchID)
                        .disabled(viewModel.isRevision)
                }
                Divider()
                formRow("Flock ID") {
                    TextField("F-902", text: $viewModel.flockID)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .flockID)
                }
                Divider()
                formRow("Breed") {
                    Picker("Breed", selection: $viewModel.breed) {
                        ForEach(PoultryBreed.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                    .tint(.hatchGreen)
                }
                Divider()
                formRow("Flock age") {
                    Stepper("\(viewModel.flockAgeWeeks) weeks", value: $viewModel.flockAgeWeeks, in: ProductionCalculator.flockAgeRange)
                        .fixedSize()
                }
                Divider()
                formRow("Site") {
                    Picker("Site", selection: $viewModel.siteID) {
                        ForEach(HatcherySite.all) { Text($0.name).tag($0.id) }
                    }
                    .labelsHidden()
                    .tint(.hatchGreen)
                }
            }
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        }
    }

    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("PRODUCTION TARGETS")
            VStack(spacing: 0) {
                formRow("Customer") {
                    TextField("Ordering broiler farm", text: $viewModel.customerName)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .customer)
                }
                Divider()
                formRow("Target Chicks") {
                    TextField("e.g. 12,500", text: $viewModel.targetChicksText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.hatchGreen)
                        .focused($focusedField, equals: .target)
                }
            }
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
            Text("Targets are used to calculate the required setter capacity and synchronization windows.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("OPERATIONAL TIMELINE")
            formRow("Egg set date") {
                DatePicker("Egg set date", selection: $viewModel.plannedSetDate, in: Calendar.current.startOfDay(for: Date())..., displayedComponents: .date)
                    .labelsHidden()
                    .tint(.hatchGreen)
            }
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))

            HStack(spacing: 12) {
                timelineTile("TRANSFER (DAY \(ProductionCalculator.transferDay))", viewModel.transferDate, icon: "arrow.right.square", tint: .hatchGreen)
                timelineTile("HATCH (DAY \(ProductionCalculator.incubationDays))", viewModel.hatchDate, icon: "oval.portrait.fill", tint: .hatchOrange)
            }
        }
    }

    private func timelineTile(_ title: String, _ date: Date, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundColor(tint)
            Text(title).font(.caption2.weight(.semibold)).foregroundColor(.secondary)
            Text(date.formatted(date: .abbreviated, time: .omitted)).font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Buffer & Calculation

    private var bufferSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("BIOLOGICAL MARGIN")
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Safety Buffer").foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.safetyBuffer.formatted(.percent.precision(.fractionLength(1))))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.hatchOrange)
                }
                Slider(value: $viewModel.safetyBuffer, in: ProductionCalculator.bufferRange, step: 0.005)
                    .tint(.hatchOrange)
                    .accessibilityLabel("Safety buffer")
                    .accessibilityValue(viewModel.safetyBuffer.formatted(.percent.precision(.fractionLength(1))))
                HStack {
                    Text("0% MIN")
                    Spacer()
                    Text("15% MAX")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        }
    }

    private var calculationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("ALLOCATION SUMMARY")
                Spacer()
                if viewModel.calculation != nil {
                    Text("OPTIMIZED")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.hatchGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.hatchGreenSoft))
                }
            }

            if let calc = viewModel.calculation {
                VStack(spacing: 12) {
                    resultRow("Standard hatchability", calc.standardHatchability.formatted(.percent.precision(.fractionLength(1))),
                              detail: "\(viewModel.breed.rawValue) at \(viewModel.flockAgeWeeks) weeks")
                    resultRow("Eggs to set", calc.requiredEggs.formatted(), detail: "incl. \(calc.bufferEggs.formatted()) buffer eggs", emphasis: true)
                    resultRow("Setter trays (shavals)", calc.setterTrays.formatted(), detail: "\(ProductionCalculator.eggsPerSetterTray) eggs per tray")
                    resultRow("Expected chicks", Int((Double(calc.requiredEggs) * calc.standardHatchability).rounded()).formatted(),
                              detail: "vs target \(calc.targetChicks.formatted())")
                    ProgressView(value: min(Double(calc.requiredEggs) / Double(viewModel.site.setterCapacity), 1)) {
                        Text("Setter load at \(viewModel.site.name)").font(.caption).foregroundColor(.secondary)
                    }
                    .tint(calc.requiredEggs > viewModel.site.setterCapacity ? .red : .hatchGreen)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
            } else {
                Text(ProductionCalculator.validate(viewModel.input) ?? "Enter a target to calculate.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
            }
        }
    }

    private func resultRow(_ title: String, _ value: String, detail: String, emphasis: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline)
                Text(detail).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Text(value)
                .font(emphasis ? .title3.weight(.bold) : .headline)
                .foregroundColor(emphasis ? .hatchGreen : .primary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var insightsSection: some View {
        let warnings = viewModel.warnings
        if !warnings.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(warnings, id: \.message) { warning in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill").foregroundColor(Color(hex: "#997700"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Supervisor Insight").font(.caption.weight(.semibold))
                            Text(warning.message).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF9E6")))
                }
            }
        }
    }

    // MARK: - Submit

    private var submitBar: some View {
        VStack(spacing: 6) {
            if let message = viewModel.validationMessage {
                Text(message).font(.caption).foregroundColor(.secondary)
            }
            Button(action: submit) {
                Text(viewModel.isRevision ? "Resubmit for Approval" : "Send for Approval")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 12).fill(viewModel.validationMessage == nil ? Color.hatchGreen : Color.gray.opacity(0.5)))
            }
            .disabled(viewModel.validationMessage != nil || viewModel.isProcessingScan)
        }
        .padding(16)
        .background(Color.white.shadow(.drop(color: .black.opacity(0.05), radius: 8, y: -2)))
    }

    private func submit() {
        focusedField = nil
        guard let draft = viewModel.makeDraft(createdBy: session.currentUser.fullName) else { return }
        do {
            submittedPlan = try session.submitPlan(draft)
        } catch {
            submitError = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(.secondary)
    }

    private func formRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer(minLength: 12)
            content()
        }
        .frame(minHeight: 48)
    }
}

/// Bottom sheet offering the two ways to attach a certificate.
private struct ScanSourceSheet: View {
    let cameraAvailable: Bool
    let onCamera: () -> Void
    let onPhotos: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Attach Certificate").font(.title3.weight(.bold))
            Text("Scan the paper certificate, or choose a photo or saved image of it.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            option(icon: "doc.viewfinder", title: "Scan with Camera",
                   subtitle: cameraAvailable ? "Edge detection and auto-crop" : "Needs a physical iPhone or iPad",
                   action: onCamera)
            option(icon: "photo.on.rectangle", title: "Choose from Photos",
                   subtitle: "Use an existing photo or screenshot", action: onPhotos)
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func option(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.hatchSurface))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ScannerIntroView()
            .environmentObject(AppSessionViewModel())
    }
}
