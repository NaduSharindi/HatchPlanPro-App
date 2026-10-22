//
//  PerformanceReportGenerator.swift
//  HatchPlanPro
//
//  Renders a batch's traceability and performance audit as an A4 PDF.
//  Approved/active batches get a projected report; closed batches include
//  actual hatch results and variance against the breed standard.
//

import UIKit

enum PerformanceReportGenerator {
    private static let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    private static let margin: CGFloat = 40
    private static let green = UIColor(red: 0x24 / 255, green: 0x5B / 255, blue: 0x24 / 255, alpha: 1)
    private static let gold = UIColor(red: 0xB7 / 255, green: 0x89 / 255, blue: 0, alpha: 1)
    private static let softGreen = UIColor(red: 0xEA / 255, green: 0xF3 / 255, blue: 0xEA / 255, alpha: 1)
    private static let softGold = UIColor(red: 0xFF / 255, green: 0xF9 / 255, blue: 0xE6 / 255, alpha: 1)

    static func fileName(for plan: HatchPlanRecord) -> String {
        let id = plan.batchID.replacingOccurrences(of: "#", with: "")
        return "Performance_Report_\(id).pdf"
    }

    /// Writes the report to the temporary directory and returns its URL.
    static func generate(for plan: HatchPlanRecord, generatedBy: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(for: plan))
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "HatchPlan Pro – \(plan.batchID)",
            kCGPDFContextAuthor as String: generatedBy,
            kCGPDFContextCreator as String: "HatchPlan Pro"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            var y = drawHeader(plan: plan)
            y = drawPerformanceCards(plan: plan, y: y)
            y = drawParameters(plan: plan, y: y)
            y = drawChart(plan: plan, y: y)

            context.beginPage()
            y = margin
            y = drawTimeline(plan: plan, y: y)
            y = drawAuthorisation(plan: plan, y: y)
            y = drawCertificate(plan: plan, y: y)
            drawFooter(plan: plan, generatedBy: generatedBy)
        }
        return url
    }

    // MARK: - Sections

    private static func drawHeader(plan: HatchPlanRecord) -> CGFloat {
        var y = margin
        draw("HatchPlan Pro", at: CGPoint(x: margin, y: y), font: .boldSystemFont(ofSize: 18), color: green)
        draw("INDUSTRIAL PRECISION", at: CGPoint(x: margin, y: y + 22), font: .systemFont(ofSize: 8, weight: .bold), color: .gray)

        let statusText = plan.status == .completed ? "VERIFIED TRACEABILITY" : "PROJECTED – \(plan.status.displayName)"
        let badge = CGRect(x: pageRect.width - margin - 170, y: y, width: 170, height: 24)
        fill(badge, color: softGreen, radius: 12)
        draw(statusText, in: badge.insetBy(dx: 8, dy: 6), font: .systemFont(ofSize: 9, weight: .bold), color: green, alignment: .center)

        y += 56
        green.setFill()
        UIBezierPath(rect: CGRect(x: margin, y: y, width: 4, height: 72)).fill()
        draw("Traceability Summary for Order \(plan.batchID)", in: CGRect(x: margin + 14, y: y, width: 480, height: 30),
             font: .boldSystemFont(ofSize: 22), color: .black)
        draw("Lifecycle report for \(plan.breed.rawValue) eggs from flock \(plan.flockID) (\(plan.flockAgeWeeks) weeks), set at \(plan.site.name).",
             in: CGRect(x: margin + 14, y: y + 34, width: 500, height: 40), font: .systemFont(ofSize: 11), color: .darkGray)
        return y + 92
    }

    private static func drawPerformanceCards(plan: HatchPlanRecord, y: CGFloat) -> CGFloat {
        let width = (pageRect.width - margin * 2 - 16) / 2
        let left = CGRect(x: margin, y: y, width: width, height: 96)
        let right = CGRect(x: margin + width + 16, y: y, width: width, height: 96)

        fill(left, color: UIColor(white: 0.96, alpha: 1), radius: 12)
        let rate = plan.actualHatchability ?? plan.standardHatchability
        draw(plan.actualHatchability == nil ? "PROJECTED HATCH RATE" : "CORE PERFORMANCE",
             at: CGPoint(x: left.minX + 14, y: left.minY + 12), font: .systemFont(ofSize: 8, weight: .bold), color: .gray)
        draw(percent(rate), at: CGPoint(x: left.minX + 14, y: left.minY + 28), font: .boldSystemFont(ofSize: 30), color: green)
        let barRect = CGRect(x: left.minX + 14, y: left.maxY - 18, width: left.width - 28, height: 6)
        fill(barRect, color: UIColor(white: 0.85, alpha: 1), radius: 3)
        fill(CGRect(x: barRect.minX, y: barRect.minY, width: barRect.width * min(rate, 1), height: 6), color: green, radius: 3)

        fill(right, color: softGold, radius: 12)
        draw("CRITICAL BUFFER", at: CGPoint(x: right.minX + 14, y: right.minY + 12), font: .systemFont(ofSize: 8, weight: .bold), color: gold)
        draw("\(percent(plan.safetyBuffer)) SAFETY MARGIN", at: CGPoint(x: right.minX + 14, y: right.minY + 28), font: .boldSystemFont(ofSize: 20), color: gold)
        draw("\(plan.calculation.bufferEggs.formatted()) extra eggs set to absorb biological variance.",
             in: CGRect(x: right.minX + 14, y: right.minY + 58, width: right.width - 28, height: 30), font: .systemFont(ofSize: 9), color: gold)
        return y + 116
    }

    private static func drawParameters(plan: HatchPlanRecord, y: CGFloat) -> CGFloat {
        var y = sectionTitle("Production Parameters", y: y)
        var rows: [(String, String)] = [
            ("Site", "\(plan.site.name) – \(plan.site.sector)"),
            ("Breed / flock", "\(plan.breed.rawValue) • \(plan.flockID) • \(plan.flockAgeWeeks) weeks"),
            ("Target chicks", plan.targetChicks.formatted()),
            ("Standard hatchability", percent(plan.standardHatchability)),
            ("Eggs set", plan.requiredEggs.formatted()),
            ("Setter trays (\(ProductionCalculator.eggsPerSetterTray) eggs/tray)", plan.setterTrays.formatted()),
            ("Expected chicks at standard", plan.expectedChicks.formatted())
        ]
        if let actual = plan.actualChicks, let variance = plan.chickVariance, let hatchVariance = plan.hatchabilityVariance {
            rows.append(("Actual chicks hatched", actual.formatted()))
            rows.append(("Variance vs order", signed(variance) + " chicks"))
            rows.append(("Variance vs standard", signedPercent(hatchVariance)))
        }
        for (index, row) in rows.enumerated() {
            if index.isMultiple(of: 2) {
                fill(CGRect(x: margin, y: y - 3, width: pageRect.width - margin * 2, height: 20), color: UIColor(white: 0.97, alpha: 1), radius: 4)
            }
            draw(row.0, at: CGPoint(x: margin + 8, y: y), font: .systemFont(ofSize: 10), color: .darkGray)
            draw(row.1, in: CGRect(x: 260, y: y, width: pageRect.width - margin - 268, height: 16),
                 font: .systemFont(ofSize: 10, weight: .semibold), color: .black, alignment: .right)
            y += 20
        }
        return y + 16
    }

    private static func drawChart(plan: HatchPlanRecord, y: CGFloat) -> CGFloat {
        var y = sectionTitle("Hatchability vs. Standard", y: y)
        let chartHeight: CGFloat = 150
        let baseline = y + chartHeight
        let bars: [(String, Double, UIColor)] = [
            ("Breed peak", plan.breed.peakHatchability, UIColor(white: 0.82, alpha: 1)),
            ("Age-adjusted standard", plan.standardHatchability, green.withAlphaComponent(0.55)),
            (plan.actualHatchability == nil ? "Projected" : "Actual", plan.actualHatchability ?? plan.standardHatchability, plan.actualHatchability == nil ? gold : green)
        ]
        let slot = (pageRect.width - margin * 2) / CGFloat(bars.count)
        for (index, bar) in bars.enumerated() {
            let height = chartHeight * CGFloat(min(bar.1, 1))
            let rect = CGRect(x: margin + slot * CGFloat(index) + slot * 0.3, y: baseline - height, width: slot * 0.4, height: height)
            fill(rect, color: bar.2, radius: 6)
            draw(percent(bar.1), in: CGRect(x: rect.minX - 10, y: rect.minY - 16, width: rect.width + 20, height: 14),
                 font: .systemFont(ofSize: 9, weight: .bold), color: .black, alignment: .center)
            draw(bar.0, in: CGRect(x: margin + slot * CGFloat(index), y: baseline + 6, width: slot, height: 14),
                 font: .systemFont(ofSize: 9, weight: .semibold), color: .gray, alignment: .center)
        }
        UIColor(white: 0.8, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: margin, y: baseline, width: pageRect.width - margin * 2, height: 1)).fill()
        y = baseline + 28
        return y
    }

    private static func drawTimeline(plan: HatchPlanRecord, y: CGFloat) -> CGFloat {
        var y = sectionTitle("Audit Timeline", y: y)
        var events: [(String, Date?)] = [
            ("Plan drafted by \(plan.createdBy)", plan.createdAt),
            ("Submitted for approval", plan.submittedAt),
            ("Reviewed by \(plan.reviewedBy ?? "manager")", plan.reviewedAt),
            ("Eggs set – incubation started", plan.executedAt)
        ]
        if plan.executedAt != nil {
            events.append(("Transfer to hatcher (day \(ProductionCalculator.transferDay))", plan.transferDate))
            events.append(("Scheduled hatch (day \(ProductionCalculator.incubationDays))", plan.hatchDateValue))
        }
        events.append(("Batch closed – actuals logged", plan.closedAt))

        for event in events {
            let done = event.1.map { $0 <= Date() } ?? false
            let dot = CGRect(x: margin + 4, y: y + 3, width: 8, height: 8)
            fill(dot, color: done ? green : UIColor(white: 0.8, alpha: 1), radius: 4)
            draw(event.0, at: CGPoint(x: margin + 22, y: y), font: .systemFont(ofSize: 10, weight: .semibold), color: done ? .black : .gray)
            draw(event.1?.formatted(date: .abbreviated, time: .shortened) ?? "Pending",
                 in: CGRect(x: 330, y: y, width: pageRect.width - margin - 330, height: 14),
                 font: .systemFont(ofSize: 10), color: .darkGray, alignment: .right)
            y += 22
        }
        return y + 12
    }

    private static func drawAuthorisation(plan: HatchPlanRecord, y: CGFloat) -> CGFloat {
        var y = sectionTitle("Digital Authorisation", y: y)
        let box = CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: 64)
        fill(box, color: softGreen, radius: 10)
        let signature = plan.approvalSignature ?? (plan.rejectionReason.map { "Rejected: \($0)" } ?? "Awaiting manager signature")
        draw("SIGNATURE", at: CGPoint(x: box.minX + 14, y: box.minY + 10), font: .systemFont(ofSize: 8, weight: .bold), color: green)
        draw(signature, in: CGRect(x: box.minX + 14, y: box.minY + 24, width: box.width - 28, height: 36), font: .systemFont(ofSize: 10, weight: .medium), color: .black)
        y = box.maxY + 16
        if let notes = plan.closingNotes, !notes.isEmpty {
            draw("Supervisor closing notes", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 10, weight: .bold), color: .black)
            draw(notes, in: CGRect(x: margin, y: y + 16, width: pageRect.width - margin * 2, height: 48), font: .systemFont(ofSize: 10), color: .darkGray)
            y += 70
        }
        return y
    }

    private static func drawCertificate(plan: HatchPlanRecord, y: CGFloat) -> CGFloat {
        let y = sectionTitle("Source Certificate (VisionKit capture)", y: y)
        let maxRect = CGRect(x: margin, y: y, width: 220, height: 300)
        if let data = plan.certificateImage, let image = UIImage(data: data) {
            let scale = min(maxRect.width / image.size.width, maxRect.height / image.size.height)
            let rect = CGRect(x: maxRect.minX, y: maxRect.minY, width: image.size.width * scale, height: image.size.height * scale)
            image.draw(in: rect)
        } else {
            fill(maxRect, color: UIColor(white: 0.95, alpha: 1), radius: 8)
            draw("No certificate image attached", in: maxRect.insetBy(dx: 10, dy: 140), font: .systemFont(ofSize: 10), color: .gray, alignment: .center)
        }
        var ocr = "Extracted text"
        if let confidence = plan.ocrConfidence { ocr += " (confidence \(percent(confidence)))" }
        draw(ocr, at: CGPoint(x: maxRect.maxX + 20, y: y), font: .systemFont(ofSize: 10, weight: .bold), color: .black)
        draw(plan.certificateText ?? "—", in: CGRect(x: maxRect.maxX + 20, y: y + 18, width: pageRect.width - margin - maxRect.maxX - 20, height: 280),
             font: .monospacedSystemFont(ofSize: 9, weight: .regular), color: .darkGray)
        return y + maxRect.height + 20
    }

    private static func drawFooter(plan: HatchPlanRecord, generatedBy: String) {
        let text = "Document ID: HP-\(plan.id.prefix(8).uppercased()) • Generated \(Date().formatted(date: .abbreviated, time: .shortened)) by \(generatedBy)"
        draw(text, in: CGRect(x: margin, y: pageRect.height - 30, width: pageRect.width - margin * 2, height: 14),
             font: .systemFont(ofSize: 8), color: .gray, alignment: .center)
    }

    // MARK: - Drawing Helpers

    private static func sectionTitle(_ title: String, y: CGFloat) -> CGFloat {
        draw(title, at: CGPoint(x: margin, y: y), font: .boldSystemFont(ofSize: 14), color: green)
        return y + 26
    }

    private static func fill(_ rect: CGRect, color: UIColor, radius: CGFloat) {
        color.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    private static func draw(_ text: String, in rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byWordWrapping
        (text as NSString).draw(in: rect, withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: style])
    }

    private static func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(1)))
    }

    private static func signedPercent(_ value: Double) -> String {
        (value >= 0 ? "+" : "") + value.formatted(.percent.precision(.fractionLength(1)))
    }

    private static func signed(_ value: Int) -> String {
        (value >= 0 ? "+" : "") + value.formatted()
    }
}
