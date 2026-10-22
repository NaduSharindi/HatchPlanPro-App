//
//  ProductionCalculator.swift
//  HatchPlanPro
//
//  The Smart Calculation Engine: translates a chick order into the raw eggs
//  and setter trays required, using breed standards adjusted for flock age.
//  Pure Foundation so it can be tested in isolation.
//

import Foundation

enum PoultryBreed: String, CaseIterable, Identifiable, Hashable {
    case ross308 = "Ross 308"
    case cobb500 = "Cobb 500"
    case hubbard = "Hubbard"
    case lohmannBrown = "Lohmann Brown"

    var id: String { rawValue }

    /// Hatch of eggs set at peak flock age (30–40 weeks), per breeder guides.
    var peakHatchability: Double {
        switch self {
        case .ross308: return 0.86
        case .cobb500: return 0.85
        case .hubbard: return 0.84
        case .lohmannBrown: return 0.82
        }
    }

    /// Matches breed names in free text such as OCR output.
    static func match(in text: String) -> PoultryBreed? {
        let normalized = text.uppercased().replacingOccurrences(of: " ", with: "")
        if normalized.contains("ROSS") { return .ross308 }
        if normalized.contains("COBB") { return .cobb500 }
        if normalized.contains("HUBBARD") { return .hubbard }
        if normalized.contains("LOHMANN") { return .lohmannBrown }
        return nil
    }
}

struct ProductionInput: Equatable {
    var targetChicks: Int
    var breed: PoultryBreed
    var flockAgeWeeks: Int
    /// Extra eggs set to absorb biological variance, as a fraction (0.05 = 5%).
    var safetyBuffer: Double
    var siteCapacity: Int
}

struct ProductionCalculation: Equatable, Hashable {
    let targetChicks: Int
    let safetyBuffer: Double
    let standardHatchability: Double
    let requiredEggs: Int
    let setterTrays: Int

    var bufferEggs: Int {
        requiredEggs - Int((Double(targetChicks) / standardHatchability).rounded(.up))
    }
}

enum ProductionWarning: Equatable {
    case exceedsSiteCapacity(required: Int, capacity: Int)
    case youngFlock
    case agedFlock
    case lowBuffer

    var message: String {
        switch self {
        case .exceedsSiteCapacity(let required, let capacity):
            return "\(required.formatted()) eggs exceeds this site's setter capacity of \(capacity.formatted()). Split the order across sites."
        case .youngFlock:
            return "Flocks under 28 weeks lay smaller eggs with lower hatchability. The standard has been reduced accordingly."
        case .agedFlock:
            return "Setting a batch with flock age over 45 weeks may require adjusted humidity levels in Stage 2."
        case .lowBuffer:
            return "A buffer under 3% leaves little margin for transport losses and infertile eggs."
        }
    }
}

enum ProductionCalculator {
    static let incubationDays = 21
    static let transferDay = 18
    /// Eggs per setter tray ("shaval").
    static let eggsPerSetterTray = 150
    static let bufferRange: ClosedRange<Double> = 0...0.15
    static let flockAgeRange: ClosedRange<Int> = 20...70
    static let maxTargetChicks = 250_000

    /// Hatchability multiplier for flock age. Hatchability climbs to a plateau
    /// between 30 and 40 weeks, then declines steadily as the flock ages.
    static func ageFactor(forWeeks weeks: Int) -> Double {
        switch weeks {
        case ..<25:
            return 0.88
        case 25..<30:
            return 0.88 + Double(weeks - 25) * 0.024
        case 30...40:
            return 1.0
        case 41...60:
            return 1.0 - Double(weeks - 40) * 0.012
        default:
            return 0.76
        }
    }

    static func standardHatchability(breed: PoultryBreed, flockAgeWeeks: Int) -> Double {
        breed.peakHatchability * ageFactor(forWeeks: flockAgeWeeks)
    }

    static func validate(_ input: ProductionInput) -> String? {
        if input.targetChicks <= 0 {
            return "Enter the number of chicks ordered."
        }
        if input.targetChicks > maxTargetChicks {
            return "Orders above \(maxTargetChicks.formatted()) chicks must be split into separate batches."
        }
        if !flockAgeRange.contains(input.flockAgeWeeks) {
            return "Flock age must be between \(flockAgeRange.lowerBound) and \(flockAgeRange.upperBound) weeks."
        }
        if !bufferRange.contains(input.safetyBuffer) {
            return "Safety buffer must be between 0% and 15%."
        }
        return nil
    }

    /// eggs = ⌈ target ÷ standard hatchability × (1 + buffer) ⌉
    /// trays = ⌈ eggs ÷ eggs per tray ⌉
    static func calculate(_ input: ProductionInput) -> ProductionCalculation? {
        guard validate(input) == nil else { return nil }

        let hatchability = standardHatchability(breed: input.breed, flockAgeWeeks: input.flockAgeWeeks)
        let baseEggs = Double(input.targetChicks) / hatchability
        let requiredEggs = Int((baseEggs * (1 + input.safetyBuffer)).rounded(.up))
        let trays = Int((Double(requiredEggs) / Double(eggsPerSetterTray)).rounded(.up))

        return ProductionCalculation(
            targetChicks: input.targetChicks,
            safetyBuffer: input.safetyBuffer,
            standardHatchability: hatchability,
            requiredEggs: requiredEggs,
            setterTrays: trays
        )
    }

    static func warnings(for input: ProductionInput, calculation: ProductionCalculation) -> [ProductionWarning] {
        var warnings: [ProductionWarning] = []
        if calculation.requiredEggs > input.siteCapacity {
            warnings.append(.exceedsSiteCapacity(required: calculation.requiredEggs, capacity: input.siteCapacity))
        }
        if input.flockAgeWeeks < 28 {
            warnings.append(.youngFlock)
        } else if input.flockAgeWeeks > 45 {
            warnings.append(.agedFlock)
        }
        if input.safetyBuffer < 0.03 {
            warnings.append(.lowBuffer)
        }
        return warnings
    }

    static func transferDate(from setDate: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: transferDay, to: setDate) ?? setDate
    }

    static func hatchDate(from setDate: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: incubationDays, to: setDate) ?? setDate
    }
}
