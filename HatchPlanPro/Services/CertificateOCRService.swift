//
//  CertificateOCRService.swift
//  HatchPlanPro
//
//  Runs Vision text recognition over scanned certificate pages and hands
//  the lines to CertificateParser.
//

import UIKit
import Vision

struct CertificateScan {
    let fields: CertificateFields
    let recognizedText: String
    /// Mean Vision confidence across recognised lines (0...1).
    let confidence: Double
    /// Compressed first page, kept as the batch's audit-trail record.
    let imageData: Data?
}

enum CertificateOCRService {
    enum OCRError: LocalizedError {
        case noImage
        case noText

        var errorDescription: String? {
            switch self {
            case .noImage:
                return "No certificate image was captured."
            case .noText:
                return "No text was found. Retake the scan in better light with the certificate flat in frame."
            }
        }
    }

    static func scan(pages: [UIImage]) async throws -> CertificateScan {
        guard let first = pages.first else { throw OCRError.noImage }

        var lines: [String] = []
        var confidences: [Float] = []
        for page in pages {
            let observations = try await recognize(page)
            var boxes: [RecognizedTextBox] = []
            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else { continue }
                let box = observation.boundingBox
                boxes.append(RecognizedTextBox(text: candidate.string, minX: box.minX, midY: box.midY, height: box.height))
                confidences.append(candidate.confidence)
            }
            lines += CertificateParser.rows(from: boxes)
        }
        guard !lines.isEmpty else { throw OCRError.noText }

        let confidence = Double(confidences.reduce(0, +)) / Double(confidences.count)
        return CertificateScan(
            fields: CertificateParser.parse(lines),
            recognizedText: lines.joined(separator: "\n"),
            confidence: confidence,
            imageData: compressedRecord(of: first)
        )
    }

    private static func recognize(_ image: UIImage) async throws -> [VNRecognizedTextObservation] {
        guard let cgImage = image.cgImage else { throw OCRError.noImage }
        let orientation = image.cgOrientation

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                // Flock and batch IDs are not dictionary words; correction mangles them.
                request.usesLanguageCorrection = false

                do {
                    try VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])
                    continuation.resume(returning: request.results ?? [])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Downscales to ~900px and JPEG-compresses so the record fits comfortably
    /// inside a Firestore document (1 MB limit).
    static func compressedRecord(of image: UIImage, maxDimension: CGFloat = 900) -> Data? {
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.45)
    }
}

private extension UIImage {
    var cgOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
