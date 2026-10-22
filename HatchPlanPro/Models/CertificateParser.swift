//
//  CertificateParser.swift
//  HatchPlanPro
//
//  Extracts batch fields from OCR'd flock health certificates and egg
//  labels. Pure Foundation so it can be tested without Vision.
//

import Foundation

struct CertificateFields: Equatable {
    var batchID: String?
    var flockID: String?
    var flockAgeWeeks: Int?
    var breed: PoultryBreed?
    var certificateDate: String?
    var targetChicks: Int?
    var customerName: String?

    var fieldsFound: Int {
        [batchID != nil, flockID != nil, flockAgeWeeks != nil, breed != nil, certificateDate != nil,
         targetChicks != nil, customerName != nil]
            .filter { $0 }.count
    }

    static let totalFields = 7
}

/// A piece of recognised text with its position, in Vision's normalised
/// coordinates (origin bottom-left, 0...1).
struct RecognizedTextBox {
    let text: String
    let minX: Double
    let midY: Double
    let height: Double
}

enum CertificateParser {
    /// Vision reads table-style certificates column by column ("Batch No:",
    /// "Flock ID:", … then "1031", "F-915", …). Regrouping boxes that share a
    /// baseline restores "Batch No: 1031" so label/value patterns match.
    static func rows(from boxes: [RecognizedTextBox]) -> [String] {
        var rows: [[RecognizedTextBox]] = []
        for box in boxes.sorted(by: { $0.midY > $1.midY }) {
            if let index = rows.firstIndex(where: { row in
                guard let anchor = row.first else { return false }
                return abs(anchor.midY - box.midY) < max(anchor.height, box.height) * 0.5
            }) {
                rows[index].append(box)
            } else {
                rows.append([box])
            }
        }
        return rows.map { row in
            row.sorted { $0.minX < $1.minX }.map(\.text).joined(separator: " ")
        }
    }

    static func parse(_ lines: [String]) -> CertificateFields {
        let text = lines.joined(separator: "\n").uppercased()
        var fields = CertificateFields()

        fields.batchID = firstMatch(#"BATCH\s*(?:ID|NO\.?|#|NUMBER)?\s*[:#\-]?\s*#?([A-Z]?\d[A-Z0-9\-]{2,})"#, in: text)
            .map { $0.hasPrefix("B") ? "#\($0)" : "#B\($0)" }

        // IDs always carry a digit, which stops "FLOCK HEALTH CERTIFICATE" matching.
        fields.flockID = firstMatch(#"FLOCK\s*(?:ID|NO\.?|#|CODE)?\s*[:#\-]?\s*((?=[A-Z0-9\-]{3,})[A-Z\-]*\d[A-Z0-9\-]*)"#, in: text)

        if let age = firstMatch(#"AGE\s*(?:\(WEEKS\)|\(WKS\))?\s*[:\-]?\s*(\d{2})"#, in: text)
            ?? firstMatch(#"\b(\d{2})\s*(?:WEEKS|WEEK|WKS|WK)\b"#, in: text),
           let weeks = Int(age), ProductionCalculator.flockAgeRange.contains(weeks) {
            fields.flockAgeWeeks = weeks
        }

        // Prefer the labelled value; fall back to any breed named on the page.
        fields.breed = firstMatch(#"(?:STRAIN|BREED)[ \t]*[:\-]?[ \t]*([A-Z ]+\d*)"#, in: text).flatMap { PoultryBreed.match(in: $0) }
            ?? PoultryBreed.match(in: text)

        if let quantity = firstMatch(#"(?:CHICK ORDER|TARGET CHICKS|ORDER QUANTITY|ORDER QTY|CHICKS ORDERED)[^0-9\n]*([\d,]{3,})"#, in: text),
           let chicks = Int(quantity.filter(\.isNumber)), chicks > 0 {
            fields.targetChicks = chicks
        }

        // Read from the original casing so the customer name isn't shouted.
        let original = lines.joined(separator: "\n")
        fields.customerName = firstMatch(#"(?i)(?:CUSTOMER|ORDERED BY|BUYER)[ \t]*[:\-][ \t]*([^\n]+)"#, in: original)
            .flatMap { $0.isEmpty ? nil : $0 }

        // OCR often reads "/" as "|" or "I"; accept those and normalise back to "/".
        fields.certificateDate = firstMatch(#"\b(\d{1,2}[/\-. |I](?:\d{1,2}|[A-Z]{3})[/\-. |I]\d{2,4})\b"#, in: text)
            .map { $0.replacingOccurrences(of: "|", with: "/") }

        return fields
    }

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range]).trimmingCharacters(in: .whitespaces)
    }
}
