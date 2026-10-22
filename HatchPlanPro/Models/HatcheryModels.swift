//
//  HatcheryModels.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-12.
//

import Foundation
import SwiftUI
import Combine
import FirebaseCore

enum HatcheryRole: String, CaseIterable, Identifiable, Codable {
    case manager = "Hatchery Manager"
    case supervisor = "Hatchery Supervisor"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .manager:
            return "Manager"
        case .supervisor:
            return "Supervisor"
        }
    }

    var displaySymbol: String {
        switch self {
        case .manager:
            return "briefcase.fill"
        case .supervisor:
            return "person.2.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .manager:
            return Color.figmaPrimary
        case .supervisor:
            return Color(hex: "#14796D")
        }
    }
}

enum HatcheryTaskState: String, Codable {
    case pending
    case inProgress
    case done

    var title: String {
        switch self {
        case .pending:
            return "Pending"
        case .inProgress:
            return "In progress"
        case .done:
            return "Complete"
        }
    }
}

struct HatcheryBatch: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let stage: String
    let eggs: Int
    let temperature: Double
    let humidity: Double
    let turnerStatus: String
    let completionProgress: Double
    let isCritical: Bool
}

struct HatcheryTask: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let state: HatcheryTaskState
    let dueLabel: String
    let iconName: String
}

struct HatcheryAlert: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let details: String
    let severity: String
    let timeLabel: String
    let iconName: String
}

struct HatcheryMetric: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let value: String
    let change: String
    let tint: Color
}

struct HatcheryUserProfile: Hashable {
    let fullName: String
    let email: String
    let role: HatcheryRole
    let preferredSecurity: String
}

enum BatchStatus: String, Codable {
    case approvedReady = "APPROVED"
    case pendingReview = "PENDING"
    case rejected = "REJECTED"
    case synced = "SYNCED"

    var displayName: String {
        switch self {
        case .approvedReady:
            return "APPROVED"
        case .pendingReview:
            return "PENDING"
        case .rejected:
            return "REJECTED"
        case .synced:
            return "SYNCED"
        }
    }

    var color: Color {
        switch self {
        case .approvedReady, .synced:
            return .hatchGreen
        case .pendingReview:
            return Color(hex: "#FFA500")
        case .rejected:
            return Color(hex: "#FF6B6B")
        }
    }
}

enum NotificationType: String, Codable {
    case criticalAlert = "CRITICAL_ALERT"
    case approvalUpdate = "APPROVAL_UPDATE"
    case systemMessage = "SYSTEM_MESSAGE"
    case weeklyReport = "WEEKLY_REPORT"

    var displayName: String {
        switch self {
        case .criticalAlert:
            return "CRITICAL ALERT"
        case .approvalUpdate:
            return "APPROVAL UPDATE"
        case .systemMessage:
            return "SYSTEM MESSAGE"
        case .weeklyReport:
            return "WEEKLY REPORT"
        }
    }

    var iconName: String {
        switch self {
        case .criticalAlert:
            return "exclamationmark.circle.fill"
        case .approvalUpdate:
            return "checkmark.circle.fill"
        case .systemMessage:
            return "gearshape.fill"
        case .weeklyReport:
            return "chart.bar.fill"
        }
    }
}

struct HatcheryNotification: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let timeLabel: String

    enum CodingKeys: String, CodingKey {
        case id, type, title, message, timestamp, timeLabel
    }
}

struct BatchInsight: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    let batchID: String
    let breed: String
    let date: String
    let status: BatchStatus
    let hatchRate: String?

    enum CodingKeys: String, CodingKey {
        case id, batchID, breed, date, status, hatchRate
    }
}

struct HatchPlanRecord: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    let batchID: String
    let breed: String
    let targetChicks: Int
    let eggSetDate: String
    let hatchDate: String
    var status: BatchStatus
    let createdBy: String
    let createdAt: Date
    var reviewedBy: String?
    var rejectionReason: String?
    var location: String

    enum CodingKeys: String, CodingKey {
        case id, batchID, breed, targetChicks, eggSetDate, hatchDate, status, createdBy, createdAt, reviewedBy, rejectionReason, location
    }
}

struct ScheduledBatch: Identifiable, Codable, Hashable {
    let id: String
    let batchID: String
    let breed: String
    let eggs: Int
    let time: String                    // "08:45"
    let timeOfDay: String               // "AM" or "PM"
    let dateLabel: String               // "TODAY, OCT 25" or "TOMORROW, OCT 26"
    let status: String                  // "CRITICAL", "ON DECK", etc.
    let statusColor: Color              // Color for status badge

    enum CodingKeys: String, CodingKey {
        case id, batchID, breed, eggs, time, timeOfDay, dateLabel, status
    }

    init(id: String = UUID().uuidString,
         batchID: String,
         breed: String,
         eggs: Int,
         time: String,
         timeOfDay: String,
         dateLabel: String,
         status: String,
         statusColor: Color) {
        self.id = id
        self.batchID = batchID
        self.breed = breed
        self.eggs = eggs
        self.time = time
        self.timeOfDay = timeOfDay
        self.dateLabel = dateLabel
        self.status = status
        self.statusColor = statusColor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedId = try container.decode(String.self, forKey: .id)
        let decodedBatchID = try container.decode(String.self, forKey: .batchID)
        let decodedBreed = try container.decode(String.self, forKey: .breed)
        let decodedEggs = try container.decode(Int.self, forKey: .eggs)
        let decodedTime = try container.decode(String.self, forKey: .time)
        let decodedTimeOfDay = try container.decode(String.self, forKey: .timeOfDay)
        let decodedDateLabel = try container.decode(String.self, forKey: .dateLabel)
        let decodedStatus = try container.decode(String.self, forKey: .status)

        let decodedStatusColor: Color
        switch decodedStatus.uppercased() {
        case "CRITICAL":
            decodedStatusColor = Color(hex: "#FFB800")
        case "ON DECK":
            decodedStatusColor = .hatchGreen
        default:
            decodedStatusColor = Color.secondary
        }

        id = decodedId
        batchID = decodedBatchID
        breed = decodedBreed
        eggs = decodedEggs
        time = decodedTime
        timeOfDay = decodedTimeOfDay
        dateLabel = decodedDateLabel
        status = decodedStatus
        statusColor = decodedStatusColor
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(batchID, forKey: .batchID)
        try container.encode(breed, forKey: .breed)
        try container.encode(eggs, forKey: .eggs)
        try container.encode(time, forKey: .time)
        try container.encode(timeOfDay, forKey: .timeOfDay)
        try container.encode(dateLabel, forKey: .dateLabel)
        try container.encode(status, forKey: .status)
    }
}

struct EfficiencyForecast: Codable, Hashable {
    let title: String                  // "Hatch window peaks in 4.5h"
    let percentage: Double             // 0.0 to 1.0
    let peakTime: String?              // "4.5h"

    init(title: String, percentage: Double, peakTime: String? = nil) {
        self.title = title
        self.percentage = percentage
        self.peakTime = peakTime
    }
}

struct HatchSensorReading: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    let title: String
    let value: String
    let unit: String
    let trend: String
    let status: String
    let iconName: String

    enum CodingKeys: String, CodingKey {
        case id, title, value, unit, trend, status, iconName
    }
}

struct HatchMetricTile: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    let title: String
    let value: String
    let caption: String
    let accent: String

    enum CodingKeys: String, CodingKey {
        case id, title, value, caption, accent
    }
}

struct HatchTimelineStep: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    let title: String
    let detail: String
    let timeLabel: String
    let state: String

    enum CodingKeys: String, CodingKey {
        case id, title, detail, timeLabel, state
    }
}

struct SourceFlockItem: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    let flockID: String
    let ageWeeks: String
    let allocated: String
    let statusLabel: String

    enum CodingKeys: String, CodingKey {
        case id, flockID, ageWeeks, allocated, statusLabel
    }
}

struct SupervisorObservation: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    let category: String
    let note: String
    let authorName: String
    let authorRole: String
    let timeLabel: String
    let attachedPhotos: [String]

    enum CodingKeys: String, CodingKey {
        case id, category, note, authorName, authorRole, timeLabel, attachedPhotos
    }
}

enum ObservationCategory: String, CaseIterable, Codable, Hashable {
    case shellQuality = "Shell Quality"
    case eggVitality = "Egg Vitality"
    case temperatureVariance = "Temperature Variance"
    case generalNote = "General Note"

    var accentColor: Color {
        switch self {
        case .shellQuality:
            return .hatchGreen
        case .eggVitality:
            return Color(hex: "#B78900")
        case .temperatureVariance:
            return Color(hex: "#245B24")
        case .generalNote:
            return Color(hex: "#7A7A7A")
        }
    }
}

struct HatchDetailSnapshot: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    let batchID: String
    let productionUnit: String
    let breed: String
    let criticalStatus: String
    let incubationStage: String
    let imageName: String
    let liveConnected: Bool
    let sensors: [HatchSensorReading]
    let metricTiles: [HatchMetricTile]
    let operationalTimeline: [HatchMetricTile]
    let sourceFlocks: [SourceFlockItem]
    let biologicalTimeline: [HatchTimelineStep]
    let observations: [SupervisorObservation]
    let eggSetDate: String
    let hatchDate: String
    let co2Value: String
    let co2Unit: String
    let co2Bars: [Double]
    let eggsToSetLabel: String
    let shavalsNeededLabel: String

    enum CodingKeys: String, CodingKey {
        case id, batchID, productionUnit, breed, criticalStatus, incubationStage, imageName, liveConnected, sensors, metricTiles, operationalTimeline, sourceFlocks, biologicalTimeline, observations, eggSetDate, hatchDate, co2Value, co2Unit, co2Bars, eggsToSetLabel, shavalsNeededLabel
    }
}

// MARK: - Vision Kit Models

struct VisionScanResult: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    let flockID: String?
    let scanDate: String?
    let confidence: Double
    let fieldsFound: Int
    let rawText: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, flockID, scanDate, confidence, fieldsFound, rawText, timestamp
    }
}

struct ScannedBatch: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    let batchID: String
    let breed: String
    let eggs: Int
    let targetChicks: Int
    let eggSetDate: String
    let hatchDate: String
    let status: BatchStatus
    let scanResult: VisionScanResult?
    let createdAt: Date
    let createdBy: String

    enum CodingKeys: String, CodingKey {
        case id, batchID, breed, eggs, targetChicks, eggSetDate, hatchDate, status, scanResult, createdAt, createdBy
    }
}
