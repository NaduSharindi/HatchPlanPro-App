//
//  HatcheryModels.swift
//  HatchPlanPro
//
//  Shared value types: roles, the signed-in user's profile, schedule entries
//  and observation categories. Batch lifecycle types live in HatchPlanDomain.
//

import Foundation
import SwiftUI

enum HatcheryRole: String, CaseIterable, Identifiable, Codable {
    case manager = "Hatchery Manager"
    case supervisor = "Hatchery Supervisor"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .manager: return "Manager"
        case .supervisor: return "Supervisor"
        }
    }

    var displaySymbol: String {
        switch self {
        case .manager: return "briefcase.fill"
        case .supervisor: return "person.2.fill"
        }
    }

    var accentColor: Color { .hatchGreen }

    var roleSummary: String {
        switch self {
        case .manager: return "Approve plans, review sites on the map, and run performance reports."
        case .supervisor: return "Scan certificates, plan batches, set eggs, and log hatch results."
        }
    }
}

struct HatcheryUserProfile: Hashable, Codable {
    var fullName: String
    var email: String
    var role: HatcheryRole
    var preferredSecurity: String
    var uid: String?
    var jobTitle: String = ""
    var employeeID: String = ""
    var siteID: String = HatcherySite.all[0].id
    var phone: String = ""
    /// Small JPEG avatar, synced in the user's Firestore profile.
    var photoData: Data?

    var site: HatcherySite { HatcherySite.site(withID: siteID) }

    var displayTitle: String {
        jobTitle.isEmpty ? role.rawValue : jobTitle
    }

    var firstName: String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }

    var initials: String {
        fullName.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }
}

/// One upcoming milestone (set, transfer or hatch) on the operational schedule.
struct ScheduledBatch: Identifiable, Hashable {
    /// The hatch plan's ID.
    let id: String
    let batchID: String
    let breed: String
    let eggs: Int
    let time: String
    let timeOfDay: String
    let dateLabel: String
    let status: String
    let statusColor: Color
}

struct EfficiencyForecast: Hashable {
    let title: String
    let percentage: Double
    var peakTime: String?
}

enum ObservationCategory: String, CaseIterable, Codable, Hashable {
    case shellQuality = "Shell Quality"
    case eggVitality = "Egg Vitality"
    case temperatureVariance = "Temperature Variance"
    case generalNote = "General Note"

    var accentColor: Color {
        switch self {
        case .shellQuality: return .hatchGreen
        case .eggVitality: return Color(hex: "#B78900")
        case .temperatureVariance: return Color(hex: "#245B24")
        case .generalNote: return Color(hex: "#7A7A7A")
        }
    }

    var icon: String {
        switch self {
        case .shellQuality: return "oval.portrait"
        case .eggVitality: return "heart.text.square"
        case .temperatureVariance: return "thermometer.medium"
        case .generalNote: return "note.text"
        }
    }
}
