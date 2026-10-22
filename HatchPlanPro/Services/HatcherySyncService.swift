//
//  HatcherySyncService.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-12.
//

import SwiftUI
import Foundation
import FirebaseFirestore

final class HatcherySyncService {
    private let database = Firestore.firestore()

    func syncDashboardSnapshot(role: HatcheryRole,
                               batches: [HatcheryBatch],
                               tasks: [HatcheryTask],
                               completion: @escaping (Result<Void, Error>) -> Void) {
        let batchPayload = batches.map { batch in
            [
                "name": batch.name,
                "stage": batch.stage,
                "eggs": batch.eggs,
                "temperature": batch.temperature,
                "humidity": batch.humidity,
                "turnerStatus": batch.turnerStatus,
                "progress": batch.completionProgress,
                "critical": batch.isCritical
            ] as [String: Any]
        }

        let taskPayload = tasks.map { task in
            [
                "title": task.title,
                "subtitle": task.subtitle,
                "state": task.state.rawValue,
                "dueLabel": task.dueLabel,
                "iconName": task.iconName
            ] as [String: Any]
        }

        let payload: [String: Any] = [
            "role": role.rawValue,
            "updatedAt": FieldValue.serverTimestamp(),
            "batches": batchPayload,
            "tasks": taskPayload,
            "securityTheme": [
                "primary": "#245B24",
                "accent": "#B78900"
            ],
            "supervisorProfile": [
                "name": role == .supervisor ? "Hatchery Supervisor" : "Hatchery Manager",
                "workflow": role == .supervisor ? "Supervisor flow" : "Manager flow"
            ]
        ]

        database.collection("dashboardSnapshots").document(role.rawValue).setData(payload, merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func syncSupervisorNotifications(notifications: [HatcheryNotification],
                                      completion: @escaping (Result<Void, Error>) -> Void) {
        let notificationPayload = notifications.map { notification in
            [
                "id": notification.id,
                "type": notification.type.rawValue,
                "title": notification.title,
                "message": notification.message,
                "timestamp": Timestamp(date: notification.timestamp),
                "timeLabel": notification.timeLabel
            ] as [String: Any]
        }

        let payload: [String: Any] = [
            "notifications": notificationPayload,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        database.collection("supervisorData").document("notifications").setData(payload, merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func syncBatchInsights(insights: [BatchInsight],
                          completion: @escaping (Result<Void, Error>) -> Void) {
        let insightPayload = insights.map { insight in
            [
                "id": insight.id,
                "batchID": insight.batchID,
                "breed": insight.breed,
                "date": insight.date,
                "status": insight.status.rawValue,
                "hatchRate": insight.hatchRate ?? ""
            ] as [String: Any]
        }

        let payload: [String: Any] = [
            "insights": insightPayload,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        database.collection("supervisorData").document("batchInsights").setData(payload, merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func fetchSupervisorNotifications(completion: @escaping (Result<[HatcheryNotification], Error>) -> Void) {
        database.collection("supervisorData").document("notifications").getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data(),
                  let notificationsData = data["notifications"] as? [[String: Any]] else {
                completion(.success([]))
                return
            }

            let notifications: [HatcheryNotification] = notificationsData.compactMap(Self.decodeNotification)

            completion(.success(notifications))
        }
    }

    func fetchBatchInsights(completion: @escaping (Result<[BatchInsight], Error>) -> Void) {
        database.collection("supervisorData").document("batchInsights").getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data(),
                  let insightsData = data["insights"] as? [[String: Any]] else {
                completion(.success([]))
                return
            }

            let insights: [BatchInsight] = insightsData.compactMap(Self.decodeBatchInsight)

            completion(.success(insights))
        }
    }

    func syncScheduledBatches(schedule: [ScheduledBatch],
                             forecast: EfficiencyForecast,
                             completion: @escaping (Result<Void, Error>) -> Void) {
        let schedulePayload = schedule.map { batch in
            [
                "id": batch.id,
                "batchID": batch.batchID,
                "breed": batch.breed,
                "eggs": batch.eggs,
                "time": batch.time,
                "timeOfDay": batch.timeOfDay,
                "dateLabel": batch.dateLabel,
                "status": batch.status
            ] as [String: Any]
        }

        let forecastPayload: [String: Any] = [
            "title": forecast.title,
            "percentage": forecast.percentage,
            "peakTime": forecast.peakTime ?? ""
        ]

        let payload: [String: Any] = [
            "schedule": schedulePayload,
            "forecast": forecastPayload,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        database.collection("supervisorData").document("schedule").setData(payload, merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func fetchScheduledBatches(completion: @escaping (Result<([ScheduledBatch], EfficiencyForecast), Error>) -> Void) {
        database.collection("supervisorData").document("schedule").getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data(),
                  let scheduleData = data["schedule"] as? [[String: Any]],
                  let forecastData = data["forecast"] as? [String: Any] else {
                completion(.success(([], EfficiencyForecast(title: "Hatch window peaks in 4.5h", percentage: 0.75))))
                return
            }

            let batches: [ScheduledBatch] = scheduleData.compactMap(Self.decodeScheduledBatch)

            let forecast: EfficiencyForecast
            if let title = forecastData["title"] as? String,
               let percentage = forecastData["percentage"] as? Double,
               let peakTime = forecastData["peakTime"] as? String {
                forecast = EfficiencyForecast(title: title, percentage: percentage, peakTime: peakTime.isEmpty ? nil : peakTime)
            } else {
                forecast = EfficiencyForecast(title: "Hatch window peaks in 4.5h", percentage: 0.75)
            }

            completion(.success((batches, forecast)))
        }
    }

    func syncHatchDetail(_ detail: HatchDetailSnapshot,
                         completion: @escaping (Result<Void, Error>) -> Void) {
        let sensorPayload = detail.sensors.map { sensor in
            [
                "id": sensor.id,
                "title": sensor.title,
                "value": sensor.value,
                "unit": sensor.unit,
                "trend": sensor.trend,
                "status": sensor.status,
                "iconName": sensor.iconName
            ] as [String: Any]
        }

        let metricPayload = detail.metricTiles.map { tile in
            [
                "id": tile.id,
                "title": tile.title,
                "value": tile.value,
                "caption": tile.caption,
                "accent": tile.accent
            ] as [String: Any]
        }

        let operationalPayload = detail.operationalTimeline.map { tile in
            [
                "id": tile.id,
                "title": tile.title,
                "value": tile.value,
                "caption": tile.caption,
                "accent": tile.accent
            ] as [String: Any]
        }

        let flockPayload = detail.sourceFlocks.map { flock in
            [
                "id": flock.id,
                "flockID": flock.flockID,
                "ageWeeks": flock.ageWeeks,
                "allocated": flock.allocated,
                "statusLabel": flock.statusLabel
            ] as [String: Any]
        }

        let timelinePayload = detail.biologicalTimeline.map { step in
            [
                "id": step.id,
                "title": step.title,
                "detail": step.detail,
                "timeLabel": step.timeLabel,
                "state": step.state
            ] as [String: Any]
        }

        let observationPayload = detail.observations.map { observation in
            [
                "id": observation.id,
                    "category": observation.category,
                "note": observation.note,
                "authorName": observation.authorName,
                "authorRole": observation.authorRole,
                "timeLabel": observation.timeLabel,
                "attachedPhotos": observation.attachedPhotos
            ] as [String: Any]
        }

        let payload: [String: Any] = [
            "batchID": detail.batchID,
            "productionUnit": detail.productionUnit,
            "breed": detail.breed,
            "criticalStatus": detail.criticalStatus,
            "incubationStage": detail.incubationStage,
            "imageName": detail.imageName,
            "liveConnected": detail.liveConnected,
            "sensors": sensorPayload,
            "metricTiles": metricPayload,
            "operationalTimeline": operationalPayload,
            "sourceFlocks": flockPayload,
            "biologicalTimeline": timelinePayload,
            "observations": observationPayload,
            "eggSetDate": detail.eggSetDate,
            "hatchDate": detail.hatchDate,
            "co2Value": detail.co2Value,
            "co2Unit": detail.co2Unit,
            "co2Bars": detail.co2Bars,
            "eggsToSetLabel": detail.eggsToSetLabel,
            "shavalsNeededLabel": detail.shavalsNeededLabel,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        database.collection("supervisorData").document("hatchDetails_\(detail.batchID)").setData(payload, merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func fetchHatchDetail(batchID: String, completion: @escaping (Result<HatchDetailSnapshot, Error>) -> Void) {
        database.collection("supervisorData").document("hatchDetails_\(batchID)").getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "HatchDetails", code: 404, userInfo: [NSLocalizedDescriptionKey: "No hatch detail found"])))
                return
            }

            let sensors: [HatchSensorReading] = (data["sensors"] as? [[String: Any]] ?? []).compactMap(Self.decodeSensorReading)

            let metricTiles: [HatchMetricTile] = (data["metricTiles"] as? [[String: Any]] ?? []).compactMap(Self.decodeMetricTile)

            let operationalTimeline: [HatchMetricTile] = (data["operationalTimeline"] as? [[String: Any]] ?? []).compactMap(Self.decodeMetricTile)

            let sourceFlocks: [SourceFlockItem] = (data["sourceFlocks"] as? [[String: Any]] ?? []).compactMap(Self.decodeSourceFlock)

            let biologicalTimeline: [HatchTimelineStep] = (data["biologicalTimeline"] as? [[String: Any]] ?? []).compactMap(Self.decodeTimelineStep)

            let observations: [SupervisorObservation] = (data["observations"] as? [[String: Any]] ?? []).compactMap(Self.decodeObservation)

            let co2Bars = data["co2Bars"] as? [Double] ?? [0.35, 0.55, 0.8, 0.72, 0.9]
            let detail = HatchDetailSnapshot(
                batchID: data["batchID"] as? String ?? batchID,
                productionUnit: data["productionUnit"] as? String ?? "PRODUCTION UNIT 04",
                breed: data["breed"] as? String ?? "Ross 308 Superior Breed",
                criticalStatus: data["criticalStatus"] as? String ?? "CRITICAL",
                incubationStage: data["incubationStage"] as? String ?? "Day 20 of 21 (Hatch Window Open)",
                imageName: data["imageName"] as? String ?? "hatch_detail_banner",
                liveConnected: data["liveConnected"] as? Bool ?? true,
                sensors: sensors,
                metricTiles: metricTiles,
                operationalTimeline: operationalTimeline,
                sourceFlocks: sourceFlocks,
                biologicalTimeline: biologicalTimeline,
                observations: observations,
                eggSetDate: data["eggSetDate"] as? String ?? "Oct 20, 2023",
                hatchDate: data["hatchDate"] as? String ?? "Nov 10, 2023",
                co2Value: data["co2Value"] as? String ?? "5,420",
                co2Unit: data["co2Unit"] as? String ?? "ppm",
                co2Bars: co2Bars,
                eggsToSetLabel: data["eggsToSetLabel"] as? String ?? "14,500",
                shavalsNeededLabel: data["shavalsNeededLabel"] as? String ?? "450"
            )

            completion(.success(detail))
        }
    }

    // MARK: - Vision Kit Scanned Batch Sync

    func syncScannedBatch(_ batch: ScannedBatch, completion: @escaping (Result<Void, Error>) -> Void) {
        var payload: [String: Any] = [
            "batchID": batch.batchID,
            "breed": batch.breed,
            "eggs": batch.eggs,
            "targetChicks": batch.targetChicks,
            "eggSetDate": batch.eggSetDate,
            "hatchDate": batch.hatchDate,
            "status": batch.status.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "createdBy": batch.createdBy
        ]

        if let scanResult = batch.scanResult {
            payload["scanResult"] = [
                "flockID": scanResult.flockID ?? "",
                "scanDate": scanResult.scanDate ?? "",
                "confidence": scanResult.confidence,
                "fieldsFound": scanResult.fieldsFound,
                "rawText": scanResult.rawText,
                "timestamp": FieldValue.serverTimestamp()
            ]
        }

        database.collection("supervisorData")
            .document("scannedBatches_\(batch.batchID)")
            .setData(payload) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }

    func fetchScannedBatches(completion: @escaping (Result<[ScannedBatch], Error>) -> Void) {
        database.collection("supervisorData")
            .whereField("batch ID", isNotEqualTo: "")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.success([]))
                    return
                }

                let batches: [ScannedBatch] = snapshot.documents.compactMap { Self.decodeScannedBatch(data: $0.data()) }

                completion(.success(batches))
            }
    }

    // MARK: - Execute Set Sync
    func syncExecuteSet(batchID: String, payload: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        // write execution record and update hatch detail document
        let docId = "execute_\(batchID)"
        var data = payload
        data["executedAt"] = FieldValue.serverTimestamp()

        database.collection("supervisorData").document(docId).setData(data) { [weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                // also set a flag on hatchDetails document for easy lookup
                let detailDoc = "hatchDetails_\(batchID)"
                guard let self else {
                    completion(.failure(NSError(domain: "HatcherySyncService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sync service was released before completion"])))
                    return
                }

                self.database.collection("supervisorData").document(detailDoc).setData(["status": "SYNCED", "lastExecutedAt": FieldValue.serverTimestamp()], merge: true) { err in
                    if let err = err {
                        completion(.failure(err))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }

    // MARK: - Manager Notifications

    /// Syncs manager notifications to Firestore.
    func syncManagerNotifications(notifications: [HatcheryNotification],
                                   completion: @escaping (Result<Void, Error>) -> Void) {
        let payload: [String: Any] = [
            "notifications": notifications.map { notification in
                [
                    "id": notification.id,
                    "type": notification.type.rawValue,
                    "title": notification.title,
                    "message": notification.message,
                    "timestamp": Timestamp(date: notification.timestamp),
                    "timeLabel": notification.timeLabel
                ] as [String: Any]
            },
            "updatedAt": FieldValue.serverTimestamp()
        ]

        database.collection("managerData").document("notifications").setData(payload, merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    /// Fetches manager notifications from Firestore.
    func fetchManagerNotifications(completion: @escaping (Result<[HatcheryNotification], Error>) -> Void) {
        database.collection("managerData").document("notifications").getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data(),
                  let notificationsData = data["notifications"] as? [[String: Any]] else {
                completion(.success([]))
                return
            }

            let notifications: [HatcheryNotification] = notificationsData.compactMap(Self.decodeNotification)
            completion(.success(notifications))
        }
    }

    private static func decodeNotification(_ dict: [String: Any]) -> HatcheryNotification? {
        guard let typeString = dict["type"] as? String,
              let type = NotificationType(rawValue: typeString),
              let title = dict["title"] as? String,
              let message = dict["message"] as? String,
              let timeLabel = dict["timeLabel"] as? String,
              let timestamp = decodeTimestamp(from: dict) else {
            return nil
        }

        return HatcheryNotification(type: type, title: title, message: message, timestamp: timestamp, timeLabel: timeLabel)
    }

    private static func decodeTimestamp(from dict: [String: Any]) -> Date? {
        if let timestamp = dict["timestamp"] as? Timestamp {
            return timestamp.dateValue()
        }
        if let date = dict["timestamp"] as? Date {
            return date
        }
        if let interval = dict["timestamp"] as? TimeInterval {
            return Date(timeIntervalSince1970: interval)
        }
        return nil
    }

    private static func decodeBatchInsight(_ dict: [String: Any]) -> BatchInsight? {
        guard let batchID = dict["batchID"] as? String,
              let breed = dict["breed"] as? String,
              let date = dict["date"] as? String,
              let statusString = dict["status"] as? String,
              let status = BatchStatus(rawValue: statusString) else {
            return nil
        }

        return BatchInsight(batchID: batchID, breed: breed, date: date, status: status, hatchRate: dict["hatchRate"] as? String)
    }

    private static func decodeScheduledBatch(_ dict: [String: Any]) -> ScheduledBatch? {
        guard let id = dict["id"] as? String,
              let batchID = dict["batchID"] as? String,
              let breed = dict["breed"] as? String,
              let eggs = dict["eggs"] as? Int,
              let time = dict["time"] as? String,
              let timeOfDay = dict["timeOfDay"] as? String,
              let dateLabel = dict["dateLabel"] as? String,
              let status = dict["status"] as? String else {
            return nil
        }

        let statusColor: Color
        switch status.uppercased() {
        case "CRITICAL":
            statusColor = Color(hex: "#FFB800")
        case "ON DECK":
            statusColor = .hatchGreen
        default:
            statusColor = .clear
        }

        return ScheduledBatch(id: id, batchID: batchID, breed: breed, eggs: eggs, time: time, timeOfDay: timeOfDay, dateLabel: dateLabel, status: status, statusColor: statusColor)
    }

    private static func decodeSensorReading(_ dict: [String: Any]) -> HatchSensorReading? {
        guard let title = dict["title"] as? String,
              let value = dict["value"] as? String,
              let unit = dict["unit"] as? String,
              let trend = dict["trend"] as? String,
              let status = dict["status"] as? String,
              let iconName = dict["iconName"] as? String else {
            return nil
        }

        return HatchSensorReading(title: title, value: value, unit: unit, trend: trend, status: status, iconName: iconName)
    }

    private static func decodeMetricTile(_ dict: [String: Any]) -> HatchMetricTile? {
        guard let title = dict["title"] as? String,
              let value = dict["value"] as? String,
              let caption = dict["caption"] as? String,
              let accent = dict["accent"] as? String else {
            return nil
        }

        return HatchMetricTile(title: title, value: value, caption: caption, accent: accent)
    }

    private static func decodeSourceFlock(_ dict: [String: Any]) -> SourceFlockItem? {
        guard let flockID = dict["flockID"] as? String,
              let ageWeeks = dict["ageWeeks"] as? String,
              let allocated = dict["allocated"] as? String,
              let statusLabel = dict["statusLabel"] as? String else {
            return nil
        }

        return SourceFlockItem(flockID: flockID, ageWeeks: ageWeeks, allocated: allocated, statusLabel: statusLabel)
    }

    private static func decodeTimelineStep(_ dict: [String: Any]) -> HatchTimelineStep? {
        guard let title = dict["title"] as? String,
              let detail = dict["detail"] as? String,
              let timeLabel = dict["timeLabel"] as? String,
              let state = dict["state"] as? String else {
            return nil
        }

        return HatchTimelineStep(title: title, detail: detail, timeLabel: timeLabel, state: state)
    }

    private static func decodeObservation(_ dict: [String: Any]) -> SupervisorObservation? {
        guard let note = dict["note"] as? String,
              let authorName = dict["authorName"] as? String,
              let authorRole = dict["authorRole"] as? String,
              let timeLabel = dict["timeLabel"] as? String,
              let attachedPhotos = dict["attachedPhotos"] as? [String] else {
            return nil
        }

        let category = ObservationCategory(rawValue: dict["category"] as? String ?? ObservationCategory.generalNote.rawValue) ?? .generalNote
        return SupervisorObservation(category: category.rawValue, note: note, authorName: authorName, authorRole: authorRole, timeLabel: timeLabel, attachedPhotos: attachedPhotos)
    }

    private static func decodeScannedBatch(data: [String: Any]) -> ScannedBatch? {
        guard let batchID = data["batchID"] as? String,
              let breed = data["breed"] as? String,
              let eggs = data["eggs"] as? Int,
              let targetChicks = data["targetChicks"] as? Int,
              let eggSetDate = data["eggSetDate"] as? String,
              let hatchDate = data["hatchDate"] as? String,
              let statusRaw = data["status"] as? String,
              let status = BatchStatus(rawValue: statusRaw),
              let createdBy = data["createdBy"] as? String else {
            return nil
        }

        var scanResult: VisionScanResult?
        if let scanData = data["scanResult"] as? [String: Any] {
            let flockID = scanData["flockID"] as? String
            let scanDate = scanData["scanDate"] as? String
            let confidence = scanData["confidence"] as? Double ?? 0.0
            let fieldsFound = scanData["fieldsFound"] as? Int ?? 0
            let rawText = scanData["rawText"] as? String ?? ""

            scanResult = VisionScanResult(
                flockID: flockID,
                scanDate: scanDate,
                confidence: confidence,
                fieldsFound: fieldsFound,
                rawText: rawText,
                timestamp: Date()
            )
        }

        return ScannedBatch(
            batchID: batchID,
            breed: breed,
            eggs: eggs,
            targetChicks: targetChicks,
            eggSetDate: eggSetDate,
            hatchDate: hatchDate,
            status: status,
            scanResult: scanResult,
            createdAt: Date(),
            createdBy: createdBy
        )
    }
}
