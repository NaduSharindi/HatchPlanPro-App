//
//  NewPlanViewModel.swift
//  HatchPlanPro
//
//  Drives the supervisor's New Plan screen: certificate scanning, flock
//  parameters, and live output from the Smart Calculation Engine.
//

import SwiftUI
import Combine

@MainActor
final class NewPlanViewModel: ObservableObject {
    @Published var batchID = ""
    @Published var breed: PoultryBreed = .ross308
    @Published var flockID = ""
    @Published var flockAgeWeeks = 34
    @Published var siteID = HatcherySite.all[0].id
    @Published var targetChicksText = ""
    @Published var safetyBuffer = 0.05
    @Published var plannedSetDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    @Published private(set) var scan: CertificateScan?
    @Published private(set) var isProcessingScan = false
    @Published var scanError: String?

    let revising: HatchPlanRecord?

    init(revising: HatchPlanRecord? = nil) {
        self.revising = revising
        guard let plan = revising else { return }
        batchID = plan.batchID
        breed = plan.breed
        flockID = plan.flockID
        flockAgeWeeks = plan.flockAgeWeeks
        siteID = plan.siteID
        targetChicksText = String(plan.targetChicks)
        safetyBuffer = plan.safetyBuffer
        plannedSetDate = max(plan.plannedSetDate, Date())
    }

    var isRevision: Bool { revising != nil }
    var site: HatcherySite { HatcherySite.site(withID: siteID) }
    var targetChicks: Int { Int(targetChicksText.filter(\.isNumber)) ?? 0 }

    var input: ProductionInput {
        ProductionInput(targetChicks: targetChicks, breed: breed, flockAgeWeeks: flockAgeWeeks,
                        safetyBuffer: safetyBuffer, siteCapacity: site.setterCapacity)
    }

    var calculation: ProductionCalculation? { ProductionCalculator.calculate(input) }

    var validationMessage: String? {
        if let message = ProductionCalculator.validate(input) { return message }
        if flockID.trimmingCharacters(in: .whitespaces).isEmpty { return "Scan the certificate or enter the source flock ID." }
        if batchID.trimmingCharacters(in: .whitespaces).isEmpty { return "Enter a batch ID." }
        return nil
    }

    var warnings: [ProductionWarning] {
        calculation.map { ProductionCalculator.warnings(for: input, calculation: $0) } ?? []
    }

    var transferDate: Date { ProductionCalculator.transferDate(from: plannedSetDate) }
    var hatchDate: Date { ProductionCalculator.hatchDate(from: plannedSetDate) }

    var hasCertificate: Bool { scan != nil || revising?.certificateImage != nil }

    // MARK: - Scanning

    func processScan(pages: [UIImage]) async {
        isProcessingScan = true
        scanError = nil
        defer { isProcessingScan = false }

        do {
            let result = try await CertificateOCRService.scan(pages: pages)
            scan = result
            apply(result.fields)
            UINotificationFeedbackGenerator().notificationOccurred(result.fields.fieldsFound > 0 ? .success : .warning)
            if result.fields.fieldsFound == 0 {
                scanError = "The certificate was attached, but no batch fields were recognised. Enter them below."
            }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            scanError = error.localizedDescription
        }
    }

    private func apply(_ fields: CertificateFields) {
        if let flock = fields.flockID { flockID = flock }
        if let age = fields.flockAgeWeeks { flockAgeWeeks = age }
        if let scannedBreed = fields.breed { breed = scannedBreed }
        if let scannedBatch = fields.batchID, !isRevision { batchID = scannedBatch }
    }

    // MARK: - Output

    func makeDraft(createdBy: String) -> HatchPlanRecord? {
        guard validationMessage == nil, let calculation else { return nil }

        var plan = HatchPlanRecord(
            id: revising?.id ?? UUID().uuidString,
            batchID: batchID.trimmingCharacters(in: .whitespaces).uppercased(),
            breed: breed,
            flockID: flockID.trimmingCharacters(in: .whitespaces).uppercased(),
            flockAgeWeeks: flockAgeWeeks,
            siteID: siteID,
            plannedSetDate: plannedSetDate,
            calculation: calculation,
            createdBy: revising?.createdBy ?? createdBy,
            createdByUID: revising?.createdByUID,
            createdAt: revising?.createdAt ?? Date()
        )
        if let revising { plan.status = revising.status }

        if let scan {
            plan.certificateText = scan.recognizedText
            plan.certificateImage = scan.imageData
            plan.ocrConfidence = scan.confidence
        } else if let revising {
            plan.certificateText = revising.certificateText
            plan.certificateImage = revising.certificateImage
            plan.ocrConfidence = revising.ocrConfidence
        }
        return plan
    }
}
