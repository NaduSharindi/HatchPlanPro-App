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

    var fieldsFound: Int {
        [batchID != nil, flockID != nil, flockAgeWeeks != nil, breed != nil, certificateDate != nil]
            .filter { $0 }.count
    }

    static let totalFields = 5
}

enum CertificateParser {
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

        fields.breed = PoultryBreed.match(in: firstMatch(#"(?:STRAIN|BREED)\s*[:\-]?\s*([A-Z ]+\d*)"#, in: text) ?? text)

        fields.certificateDate = firstMatch(#"\b(\d{1,2}[/\-. ](?:\d{1,2}|[A-Z]{3})[/\-. ]\d{2,4})\b"#, in: text)

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
