//
//  AppSessionViewModel.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-12.
//

import Foundation
import Combine
import SwiftUI
import UIKit
import FirebaseAuth

final class AppSessionViewModel: ObservableObject {
    @Published var currentRole: HatcheryRole = .manager
    @Published var currentUser = HatcheryUserProfile(
        fullName: "Ms Nadunika",
        email: "lead.agronomist@hatchplan.pro",
        role: .manager,
        preferredSecurity: "PIN + Face ID"
    )
    @Published var isPINVerified = false
    @Published var isAuthenticated = false
    @Published var preferredSecurityMethod = "PIN"
    @Published var lastSyncSummary = "Local draft"
    @Published var selectedTabIndex = 0
    @Published var supervisorNotifications: [HatcheryNotification] = []
    @Published var unreadSupervisorNotifCount: Int = 0
    @Published var batchInsights: [BatchInsight] = []
    @Published var hatchPlans: [HatchPlanRecord] = []
    @Published var scheduledBatches: [ScheduledBatch] = []
    @Published var efficiencyForecast = EfficiencyForecast(title: "Hatch window peaks in 4.5h", percentage: 0.75)
    @Published var hatchDetailSnapshots: [String: HatchDetailSnapshot] = [:]
    @Published var scannedBatches: [ScannedBatch] = []
    @Published var accessibilityTextScale: Double = 1.0
    @Published private(set) var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    @Published var biometricsEnabled: Bool = BiometricAuthService.shared.isEnabled
    @Published var isUpdatingBiometrics = false
    @Published var biometricErrorMessage: String?

    // MARK: - Auth & Backend State
    @Published var isLoadingAuth: Bool = false
    @Published var authErrorMessage: String?
    @Published var showAuthError: Bool = false
    @Published var managerNotifications: [HatcheryNotification] = []
    @Published var unreadManagerNotifCount: Int = 0

    private let syncService = HatcherySyncService()
    private let planRepository = HatchPlanRepository.shared
    private var cancellables = Set<AnyCancellable>()
    private let authService = FirebaseAuthService.shared
    private let biometricService = BiometricAuthService.shared
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var voiceOverObserver: NSObjectProtocol?

    var preferredDynamicTypeSize: DynamicTypeSize {
        switch accessibilityTextScale {
        case ..<0.9:
            return .xSmall
        case ..<1.0:
            return .small
        case ..<1.1:
            return .medium
        case ..<1.2:
            return .large
        case ..<1.3:
            return .xLarge
        case ..<1.4:
            return .xxLarge
        default:
            return .xxxLarge
        }
    }

    let managerBatches: [HatcheryBatch] = [
        HatcheryBatch(name: "Batch A-24", stage: "Incubation Day 7", eggs: 1200, temperature: 37.8, humidity: 58, turnerStatus: "Auto-turning", completionProgress: 0.62, isCritical: false),
        HatcheryBatch(name: "Batch B-08", stage: "Hatch Prep", eggs: 980, temperature: 38.2, humidity: 64, turnerStatus: "Needs check", completionProgress: 0.84, isCritical: true),
        HatcheryBatch(name: "Batch C-11", stage: "Brooding", eggs: 760, temperature: 37.5, humidity: 55, turnerStatus: "Stable", completionProgress: 0.45, isCritical: false)
    ]

    let supervisorBatches: [HatcheryBatch] = [
        HatcheryBatch(name: "Hatch Room 1", stage: "Monitoring", eggs: 450, temperature: 37.6, humidity: 61, turnerStatus: "Manual follow-up", completionProgress: 0.52, isCritical: false),
        HatcheryBatch(name: "Incubator 3", stage: "Critical Alert", eggs: 310, temperature: 39.1, humidity: 68, turnerStatus: "Door opened", completionProgress: 0.91, isCritical: true),
        HatcheryBatch(name: "Incubator 5", stage: "Cooling Down", eggs: 540, temperature: 37.4, humidity: 56, turnerStatus: "Normal", completionProgress: 0.37, isCritical: false)
    ]

    let managerTasks: [HatcheryTask] = [
        HatcheryTask(title: "Approve batch transfer", subtitle: "Review movement from Brooder 2 to Brooder 3", state: .pending, dueLabel: "Due 10:30 AM", iconName: "checklist"),
        HatcheryTask(title: "Share production report", subtitle: "Export daily performance to stakeholder email", state: .inProgress, dueLabel: "Due today", iconName: "square.and.arrow.up"),
        HatcheryTask(title: "Schedule maintenance", subtitle: "Confirm humidifier service window", state: .done, dueLabel: "Completed", iconName: "wrench.and.screwdriver")
    ]

    let supervisorTasks: [HatcheryTask] = [
        HatcheryTask(title: "Confirm temperature log", subtitle: "Record readings for every active incubator", state: .inProgress, dueLabel: "Due now", iconName: "thermometer.medium"),
        HatcheryTask(title: "Review hatch tray count", subtitle: "Compare tray numbers with night shift log", state: .pending, dueLabel: "Due 2:00 PM", iconName: "tray.full"),
        HatcheryTask(title: "Escalate alert to manager", subtitle: "Send the latest anomaly report", state: .done, dueLabel: "Completed", iconName: "exclamationmark.triangle")
    ]

    let managerAlerts: [HatcheryAlert] = [
        HatcheryAlert(title: "Batch B-08 humidity spike", details: "Humidity rose above the upper threshold for 8 minutes.", severity: "Critical", timeLabel: "5 min ago", iconName: "drop.triangle.fill"),
        HatcheryAlert(title: "Maintenance window ready", details: "Equipment service can be scheduled after 3:00 PM.", severity: "Info", timeLabel: "18 min ago", iconName: "calendar.badge.clock")
    ]

    let supervisorAlerts: [HatcheryAlert] = [
        HatcheryAlert(title: "Incubator 3 door open", details: "Immediate attention is required to stabilise the chamber.", severity: "Critical", timeLabel: "2 min ago", iconName: "door.left.hand.open"),
        HatcheryAlert(title: "Brooder temperature steady", details: "Readings have been stable for the last 30 minutes.", severity: "Info", timeLabel: "12 min ago", iconName: "thermometer.sun.fill")
    ]

    var defaultHatchDetails: [HatchDetailSnapshot] {
        [
            HatchDetailSnapshot(
                batchID: "#B7-902",
                productionUnit: "PRODUCTION UNIT 04",
                breed: "Ross 308 Superior Breed",
                criticalStatus: "CRITICAL",
                incubationStage: "Day 20 of 21 (Hatch Window Open)",
                imageName: "hatch_detail_banner",
                liveConnected: true,
                sensors: [
                    HatchSensorReading(title: "TEMP", value: "37.5", unit: "°C", trend: "STABLE", status: "STABLE", iconName: "thermometer.medium"),
                    HatchSensorReading(title: "HUMIDITY", value: "62.0", unit: "%", trend: "RISING", status: "RISING", iconName: "drop.fill")
                ],
                metricTiles: [
                    HatchMetricTile(title: "EGGS TO SET", value: "14,500", caption: "Batch target capacity", accent: "#245B24"),
                    HatchMetricTile(title: "SHAVALS NEEDED", value: "450", caption: "Estimated supply req.", accent: "#B78900")
                ],
                operationalTimeline: [
                    HatchMetricTile(title: "EGG SET DATE", value: "Oct 20, 2023", caption: "Operational timeline", accent: "#245B24"),
                    HatchMetricTile(title: "HATCH DATE", value: "Nov 10, 2023", caption: "Operational timeline", accent: "#B78900")
                ],
                sourceFlocks: [
                    SourceFlockItem(flockID: "F-902", ageWeeks: "34 weeks", allocated: "6,000", statusLabel: "ALLOCATED"),
                    SourceFlockItem(flockID: "F-815", ageWeeks: "41 weeks", allocated: "4,500", statusLabel: "ALLOCATED"),
                    SourceFlockItem(flockID: "F-722", ageWeeks: "34 weeks", allocated: "4,000", statusLabel: "ALLOCATED")
                ],
                biologicalTimeline: [
                    HatchTimelineStep(title: "Egg Setting", detail: "Day 1: 14,500 eggs placed in primary setters.", timeLabel: "COMPLETED", state: "completed"),
                    HatchTimelineStep(title: "Incubation Phase", detail: "Days 1-18: Temperature and humidity cycling active.", timeLabel: "ACTIVE", state: "active"),
                    HatchTimelineStep(title: "Transfer to Hatcher", detail: "Day 19: Transfer to hatcher baskets for final stage.", timeLabel: "UPCOMING", state: "upcoming"),
                    HatchTimelineStep(title: "Final Hatch Completion", detail: "Day 21: Pulling and quality assessment.", timeLabel: "UPCOMING", state: "upcoming")
                ],
                observations: [
                    SupervisorObservation(category: ObservationCategory.shellQuality.rawValue, note: "Egg weight loss trending at 11.2%. Batch #B7-902 is slightly ahead of schedule. Ventilator intake adjusted +5% to compensate for metabolic heat.", authorName: "Dr. Adrian Miller", authorRole: "HEAD SUPERVISOR", timeLabel: "08:15 AM TODAY", attachedPhotos: ["observation_1", "observation_2", "observation_3", "observation_4"])
                ],
                eggSetDate: "Oct 20, 2023",
                hatchDate: "Nov 10, 2023",
                co2Value: "5,420",
                co2Unit: "ppm",
                co2Bars: [0.35, 0.55, 0.8, 0.72, 0.9],
                eggsToSetLabel: "14,500",
                shavalsNeededLabel: "450"
            )
        ]
    }

    func initializeHatchDetails() {
        for detail in defaultHatchDetails {
            hatchDetailSnapshots[detail.batchID] = detail
        }
    }

    /// Hatch-detail view model for a real batch. Sensor tiles remain simulated
    /// until incubators are connected (IoT is out of scope for this release).
    func detailSnapshot(for plan: HatchPlanRecord, observations: [SupervisorObservation]) -> HatchDetailSnapshot {
        let day = plan.incubationDay()
        func state(from start: Int, to end: Int) -> (String, String) {
            if plan.status == .completed || day > end { return ("COMPLETED", "completed") }
            if plan.status == .active && day >= start { return ("ACTIVE", "active") }
            return ("UPCOMING", "upcoming")
        }
        let setting = plan.executedAt == nil ? ("UPCOMING", "upcoming") : ("COMPLETED", "completed")
        let incubation = state(from: 1, to: ProductionCalculator.transferDay - 1)
        let transfer = state(from: ProductionCalculator.transferDay, to: ProductionCalculator.incubationDays - 1)
        let hatch = plan.status == .completed ? ("COMPLETED", "completed") : state(from: ProductionCalculator.incubationDays, to: Int.max)
        let isCritical = plan.status == .active && plan.daysUntilHatch() <= 1

        return HatchDetailSnapshot(
            batchID: plan.batchID,
            productionUnit: plan.site.name.uppercased(),
            breed: plan.breed.rawValue,
            criticalStatus: isCritical ? "CRITICAL" : plan.status.displayName,
            incubationStage: plan.status == .active ? "Day \(day) of \(ProductionCalculator.incubationDays)" : plan.status.displayName.capitalized,
            imageName: "hatch_detail_banner",
            liveConnected: plan.status == .active,
            sensors: [
                HatchSensorReading(title: "TEMP", value: "37.5", unit: "°C", trend: "STABLE", status: "STABLE", iconName: "thermometer.medium"),
                HatchSensorReading(title: "HUMIDITY", value: day >= ProductionCalculator.transferDay ? "65.0" : "55.0", unit: "%", trend: "STABLE", status: "STABLE", iconName: "drop.fill")
            ],
            metricTiles: [
                HatchMetricTile(title: "EGGS TO SET", value: plan.requiredEggs.formatted(), caption: "Batch target capacity", accent: "#245B24"),
                HatchMetricTile(title: "SETTER TRAYS", value: plan.setterTrays.formatted(), caption: "\(ProductionCalculator.eggsPerSetterTray) eggs per tray", accent: "#B78900")
            ],
            operationalTimeline: [
                HatchMetricTile(title: "EGG SET DATE", value: plan.eggSetDate, caption: "Operational timeline", accent: "#245B24"),
                HatchMetricTile(title: "HATCH DATE", value: plan.hatchDate, caption: "Operational timeline", accent: "#B78900")
            ],
            sourceFlocks: [
                SourceFlockItem(flockID: plan.flockID, ageWeeks: "\(plan.flockAgeWeeks) weeks", allocated: plan.requiredEggs.formatted(), statusLabel: "ALLOCATED")
            ],
            biologicalTimeline: [
                HatchTimelineStep(title: "Egg Setting", detail: "Day 0: \(plan.requiredEggs.formatted()) eggs placed in setters.", timeLabel: setting.0, state: setting.1),
                HatchTimelineStep(title: "Incubation Phase", detail: "Days 1-\(ProductionCalculator.transferDay - 1): temperature and humidity cycling.", timeLabel: incubation.0, state: incubation.1),
                HatchTimelineStep(title: "Transfer to Hatcher", detail: "Day \(ProductionCalculator.transferDay): transfer to hatcher baskets.", timeLabel: transfer.0, state: transfer.1),
                HatchTimelineStep(title: "Final Hatch Completion", detail: "Day \(ProductionCalculator.incubationDays): pulling and quality assessment.", timeLabel: hatch.0, state: hatch.1)
            ],
            observations: observations,
            eggSetDate: plan.eggSetDate,
            hatchDate: plan.hatchDate,
            co2Value: "5,420",
            co2Unit: "ppm",
            co2Bars: [0.35, 0.55, 0.8, 0.72, 0.9],
            eggsToSetLabel: plan.requiredEggs.formatted(),
            shavalsNeededLabel: plan.setterTrays.formatted()
        )
    }

    func detailSnapshot(for batch: ScheduledBatch) -> HatchDetailSnapshot {
        if let plan = hatchPlans.first(where: { $0.batchID == batch.batchID }) {
            return detailSnapshot(for: plan, observations: hatchDetailSnapshots[batch.batchID]?.observations ?? [])
        }
        if let snapshot = hatchDetailSnapshots[batch.batchID] {
            return snapshot
        }

        return HatchDetailSnapshot(
            batchID: batch.batchID,
            productionUnit: "PRODUCTION UNIT 04",
            breed: batch.breed,
            criticalStatus: batch.status.isEmpty ? "ON TRACK" : batch.status,
            incubationStage: batch.dateLabel,
            imageName: "hatch_detail_banner",
            liveConnected: true,
            sensors: [
                HatchSensorReading(title: "TEMP", value: "37.5", unit: "°C", trend: "STABLE", status: "STABLE", iconName: "thermometer.medium"),
                HatchSensorReading(title: "HUMIDITY", value: "62.0", unit: "%", trend: "RISING", status: "RISING", iconName: "drop.fill")
            ],
            metricTiles: [
                HatchMetricTile(title: "EGGS TO SET", value: String(batch.eggs), caption: "Batch target capacity", accent: "#245B24"),
                HatchMetricTile(title: "SHAVALS NEEDED", value: "450", caption: "Estimated supply req.", accent: "#B78900")
            ],
            operationalTimeline: [
                HatchMetricTile(title: "EGG SET DATE", value: "Oct 20, 2023", caption: "Operational timeline", accent: "#245B24"),
                HatchMetricTile(title: "HATCH DATE", value: "Nov 10, 2023", caption: "Operational timeline", accent: "#B78900")
            ],
            sourceFlocks: [
                SourceFlockItem(flockID: "F-902", ageWeeks: "34 weeks", allocated: "6,000", statusLabel: "ALLOCATED"),
                SourceFlockItem(flockID: "F-815", ageWeeks: "41 weeks", allocated: "4,500", statusLabel: "ALLOCATED"),
                SourceFlockItem(flockID: "F-722", ageWeeks: "34 weeks", allocated: "4,000", statusLabel: "ALLOCATED")
            ],
            biologicalTimeline: [
                HatchTimelineStep(title: "Egg Setting", detail: "Day 1: eggs placed in primary setters.", timeLabel: "COMPLETED", state: "completed"),
                HatchTimelineStep(title: "Incubation Phase", detail: "Temperature and humidity cycling active.", timeLabel: "ACTIVE", state: "active"),
                HatchTimelineStep(title: "Transfer to Hatcher", detail: "Transfer to hatcher baskets for final stage.", timeLabel: "UPCOMING", state: "upcoming"),
                HatchTimelineStep(title: "Final Hatch Completion", detail: "Pulling and quality assessment.", timeLabel: "UPCOMING", state: "upcoming")
            ],
            observations: [
                SupervisorObservation(category: ObservationCategory.generalNote.rawValue, note: "Batch monitoring continues with stable readings.", authorName: "Dr. Adrian Miller", authorRole: "HEAD SUPERVISOR", timeLabel: "08:15 AM TODAY", attachedPhotos: ["observation_1", "observation_2", "observation_3", "observation_4"])
            ],
            eggSetDate: "Oct 20, 2023",
            hatchDate: "Nov 10, 2023",
            co2Value: "5,420",
            co2Unit: "ppm",
            co2Bars: [0.35, 0.55, 0.8, 0.72, 0.9],
            eggsToSetLabel: String(batch.eggs),
            shavalsNeededLabel: "450"
        )
    }

    /// Rebuilds the operational schedule from approved and incubating batches:
    /// each contributes its next milestone (set, transfer or hatch).
    private func rebuildSchedule(from plans: [HatchPlanRecord]) {
        let now = Date()
        let calendar = Calendar.current
        var entries: [(date: Date, batch: ScheduledBatch)] = []

        for plan in plans {
            let milestone: (date: Date, label: String)?
            switch plan.status {
            case .approvedReady:
                milestone = (plan.plannedSetDate, "SET")
            case .active:
                milestone = plan.transferDate > now ? (plan.transferDate, "TRANSFER") : (plan.hatchDateValue, "HATCH")
            default:
                milestone = nil
            }
            guard let milestone else { continue }

            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: milestone.date)).day ?? 0
            let status: String
            let color: Color
            if milestone.label == "HATCH" && days <= 1 {
                status = "CRITICAL"
                color = Color(hex: "#FFB800")
            } else if days <= 0 {
                status = "ON DECK"
                color = .hatchGreen
            } else {
                status = milestone.label
                color = .secondary
            }

            let time = milestone.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
            let amPM = calendar.component(.hour, from: milestone.date) < 12 ? "AM" : "PM"
            entries.append((milestone.date, ScheduledBatch(
                id: plan.id,
                batchID: plan.batchID,
                breed: plan.breed.rawValue,
                eggs: plan.requiredEggs,
                time: time,
                timeOfDay: amPM,
                dateLabel: Self.scheduleDateLabel(for: milestone.date, relativeTo: now),
                status: status,
                statusColor: color
            )))
        }

        scheduledBatches = entries.sorted { $0.date < $1.date }.map(\.batch)

        if let next = plans.filter({ $0.status == .active }).min(by: { $0.hatchDateValue < $1.hatchDateValue }) {
            let days = next.daysUntilHatch(asOf: now)
            let title = days == 0 ? "\(next.batchID) hatch window is open" : "\(next.batchID) hatches in \(days) day\(days == 1 ? "" : "s")"
            efficiencyForecast = EfficiencyForecast(title: title, percentage: next.incubationProgress(asOf: now), peakTime: "\(days)d")
        } else {
            efficiencyForecast = EfficiencyForecast(title: "No batches incubating", percentage: 0)
        }
    }

    private static func scheduleDateLabel(for date: Date, relativeTo now: Date) -> String {
        let calendar = Calendar.current
        let monthDay = date.formatted(.dateTime.month(.abbreviated).day()).uppercased()
        if calendar.isDate(date, inSameDayAs: now) { return "TODAY, \(monthDay)" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return "TOMORROW, \(monthDay)"
        }
        if date < now { return "OVERDUE, \(monthDay)" }
        return "\(date.formatted(.dateTime.weekday(.abbreviated)).uppercased()), \(monthDay)"
    }

    var batches: [HatcheryBatch] {
        currentRole == .manager ? managerBatches : supervisorBatches
    }

    var tasks: [HatcheryTask] {
        currentRole == .manager ? managerTasks : supervisorTasks
    }

    var alerts: [HatcheryAlert] {
        currentRole == .manager ? managerAlerts : supervisorAlerts
    }

    var metrics: [HatcheryMetric] {
        switch currentRole {
        case .manager:
            return [
                HatcheryMetric(title: "Hatch rate", value: "92%", change: "+4.2%", tint: Color(hex: "#14796D")),
                HatcheryMetric(title: "Active batches", value: "3", change: "1 critical", tint: Color.figmaPrimary),
                HatcheryMetric(title: "Avg. temp.", value: "37.8°C", change: "Stable", tint: Color(hex: "#0F4C81"))
            ]
        case .supervisor:
            return [
                HatcheryMetric(title: "Rooms monitored", value: "5", change: "1 urgent", tint: Color(hex: "#14796D")),
                HatcheryMetric(title: "Tasks complete", value: "8/10", change: "+2 today", tint: Color.figmaPrimary),
                HatcheryMetric(title: "Alert response", value: "2m", change: "Fast", tint: Color(hex: "#0F4C81"))
            ]
        }
    }

    var pendingPlans: [HatchPlanRecord] {
        hatchPlans.filter { $0.status == .pendingReview }
            .sorted { ($0.submittedAt ?? $0.createdAt) < ($1.submittedAt ?? $1.createdAt) }
    }

    var approvedPlans: [HatchPlanRecord] {
        hatchPlans.filter { $0.status == .approvedReady }
    }

    var rejectedPlans: [HatchPlanRecord] {
        hatchPlans.filter { $0.status == .rejected }
    }

    var activePlans: [HatchPlanRecord] {
        hatchPlans.filter { $0.status == .active }
            .sorted { $0.hatchDateValue < $1.hatchDateValue }
    }

    var completedPlans: [HatchPlanRecord] {
        hatchPlans.filter { $0.status == .completed }
            .sorted { ($0.closedAt ?? $0.updatedAt) > ($1.closedAt ?? $1.updatedAt) }
    }

    func plan(withID id: String) -> HatchPlanRecord? {
        hatchPlans.first { $0.id == id }
    }

    /// Batches saved on this device that Firestore has not acknowledged yet.
    @Published private(set) var pendingSyncCount = 0

    var todayScheduledBatches: [ScheduledBatch] {
        scheduledBatches.filter { $0.dateLabel.uppercased().contains("TODAY") }
    }

    var hasTodaySchedule: Bool {
        !todayScheduledBatches.isEmpty
    }

    var todaySummary: String {
        switch currentRole {
        case .manager:
            return "Track production, review critical batches, and keep hatch rates predictable."
        case .supervisor:
            return "Monitor incubators, capture readings, and escalate anomalies before they spread."
        }
    }

    func chooseRole(_ role: HatcheryRole) {
        currentRole = role
        currentUser = HatcheryUserProfile(
            fullName: role == .manager ? "Ms Nadunika" : "Hatchery Supervisor",
            email: role == .manager ? "lead.agronomist@hatchplan.pro" : "supervisor@hatchplanpro.com",
            role: role,
            preferredSecurity: preferredSecurityMethod
        )
    }

    func setAccessibilityTextScale(_ scale: Double) {
        accessibilityTextScale = min(max(scale, 0.85), 1.45)
    }

    func refreshVoiceOverStatus() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    }

    func openAccessibilitySettings() {
        openSystemSettings()
    }

    var voiceOverToggleBinding: Binding<Bool> {
        Binding(
            get: { self.isVoiceOverRunning },
            set: { _ in self.openAccessibilitySettings() }
        )
    }

    // MARK: - Biometrics

    var biometricType: BiometricType { biometricService.biometricType }

    var biometricAvailability: BiometricAvailability { biometricService.availability }

    var biometricName: String { biometricService.biometricName }

    /// True when this device can actually run a biometric prompt right now.
    var canEnableBiometrics: Bool { biometricService.isBiometricAvailable }

    /// Whether the user should be invited to turn biometrics on after signing in.
    /// Respects an earlier "Skip for now" so the prompt never becomes a nag.
    var shouldOfferBiometricEnrollment: Bool {
        biometricService.isBiometricAvailable
        && !biometricService.isEnabled
        && !hasDeclinedBiometricSetup
    }

    var hasDeclinedBiometricSetup: Bool {
        UserDefaults.standard.bool(forKey: Self.biometricSetupDeclinedKey)
    }

    func markBiometricSetupDeclined() {
        UserDefaults.standard.set(true, forKey: Self.biometricSetupDeclinedKey)
    }

    private static let biometricSetupDeclinedKey = "hatchplan.biometricSetupDeclined"

    /// Keeps the published flag in step with the Keychain, which is the source of truth.
    func refreshBiometricState() {
        biometricsEnabled = biometricService.isEnabled
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// Turns biometric sign-in on or off.
    ///
    /// Enabling always runs the real system prompt first, so the stored preference
    /// can never claim biometrics work when the user never verified.
    func setBiometricEnabled(_ enabled: Bool, completion: ((Bool) -> Void)? = nil) {
        biometricErrorMessage = nil

        guard enabled else {
            biometricService.disableBiometric()
            biometricsEnabled = false
            completion?(true)
            return
        }

        guard biometricService.isBiometricAvailable else {
            biometricsEnabled = false
            biometricErrorMessage = biometricService.unavailableReason
            completion?(false)
            return
        }

        isUpdatingBiometrics = true

        biometricService.enableBiometricWithAuthentication { [weak self] result in
            guard let self else { return }
            self.isUpdatingBiometrics = false

            switch result {
            case .success:
                self.biometricsEnabled = true
                UserDefaults.standard.set(false, forKey: Self.biometricSetupDeclinedKey)
                self.preferredSecurityMethod = self.biometricService.biometricName
                self.currentUser = HatcheryUserProfile(
                    fullName: self.currentUser.fullName,
                    email: self.currentUser.email,
                    role: self.currentRole,
                    preferredSecurity: self.biometricService.biometricName
                )
                completion?(true)

            case .failure(let error):
                self.biometricsEnabled = false
                self.biometricErrorMessage = self.biometricService.localizedErrorMessage(from: error)
                completion?(false)
            }
        }
    }

    var needsBiometricUnlock: Bool {
        !isAuthenticated && authService.isSignedIn && biometricService.isEnabled
    }

    func restoreStoredSession() {
        guard let email = KeychainHelper.shared.read(forKey: KeychainHelper.userEmailKey),
              let name = KeychainHelper.shared.read(forKey: KeychainHelper.userNameKey),
              let roleRaw = KeychainHelper.shared.read(forKey: KeychainHelper.userRoleKey),
              let role = HatcheryRole(rawValue: roleRaw) else {
            return
        }

        currentRole = role
        currentUser = HatcheryUserProfile(
            fullName: name,
            email: email,
            role: role,
            preferredSecurity: biometricService.isEnabled ? biometricService.biometricName : preferredSecurityMethod
        )
        biometricsEnabled = biometricService.isEnabled
    }

    func attemptBiometricUnlock(completion: @escaping (Bool, Error?) -> Void) {
        guard needsBiometricUnlock else {
            completion(false, nil)
            return
        }

        restoreStoredSession()

        biometricService.authenticate(reason: "Unlock HatchPlan Pro with \(biometricService.biometricName).") { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.completeAuthentication(usingFaceID: true, biometricAlreadyVerified: true)
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }

    var canUseBiometricSignIn: Bool {
        authService.isSignedIn && biometricService.isEnabled && biometricService.isBiometricAvailable
    }

    func recordCredentials(email: String, name: String? = nil) {
        currentUser = HatcheryUserProfile(
            fullName: name?.isEmpty == false ? name! : currentUser.fullName,
            email: email,
            role: currentRole,
            preferredSecurity: preferredSecurityMethod
        )
    }

    func markPINVerified() {
        isPINVerified = true
    }

    // MARK: - Batch Lifecycle
    //
    // Planning → Verification → Documentation → Execution → Closing.
    // Every mutation is role-checked, validated against BatchStatus's
    // transition table, saved to Core Data and pushed to Firestore.

    /// Generates a batch ID that is unique among known plans.
    func nextBatchID() -> String {
        let existing = Set(hatchPlans.map(\.batchID))
        var candidate: String
        repeat {
            candidate = "#B\(Int.random(in: 1030...9999))"
        } while existing.contains(candidate)
        return candidate
    }

    /// Supervisor: sends a new or revised plan for manager review.
    @discardableResult
    func submitPlan(_ draft: HatchPlanRecord) throws -> HatchPlanRecord {
        try requireRole(.supervisor, to: "submit production plans")
        guard ProductionCalculator.validate(ProductionInput(
            targetChicks: draft.targetChicks, breed: draft.breed, flockAgeWeeks: draft.flockAgeWeeks,
            safetyBuffer: draft.safetyBuffer, siteCapacity: draft.site.setterCapacity)) == nil else {
            throw BatchLifecycleError.invalidInput("The plan's production figures are invalid. Recalculate before submitting.")
        }
        guard !draft.flockID.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw BatchLifecycleError.invalidInput("Enter or scan the source flock ID.")
        }
        if hatchPlans.contains(where: { $0.batchID == draft.batchID && $0.id != draft.id }) {
            throw BatchLifecycleError.invalidInput("Batch \(draft.batchID) already exists. Use a different batch ID.")
        }

        let current = plan(withID: draft.id)?.status ?? .draft
        guard current.canTransition(to: .pendingReview) else {
            throw BatchLifecycleError.invalidTransition(from: current, to: .pendingReview)
        }

        var plan = draft
        plan.status = .pendingReview
        plan.submittedAt = Date()
        plan.reviewedBy = nil
        plan.reviewedAt = nil
        plan.rejectionReason = nil
        plan.approvalSignature = nil
        plan.createdByUID = plan.createdByUID ?? authService.currentUser?.uid
        planRepository.save(plan)

        let verb = current == .rejected ? "resubmitted" : "submitted"
        appendSupervisorNotification(type: .approvalUpdate,
                                     title: "Plan for Batch \(plan.batchID) \(verb) for review.",
                                     message: "Waiting for manager approval before execution.")
        appendManagerNotification(type: .approvalUpdate,
                                  title: "Plan Approval Requested",
                                  message: "\(plan.createdBy) submitted \(plan.batchID) for \(plan.site.name).")
        return plan
    }

    /// Manager: signs with Face ID / passcode and approves one plan.
    @MainActor
    func approvePlan(planID: String) async throws {
        try await approvePlans(planIDs: [planID])
    }

    /// Manager: one signature authorises every plan in the list.
    @MainActor
    func approvePlans(planIDs: [String]) async throws {
        try requireRole(.manager, to: "approve production plans")
        let plans = try planIDs.map { id -> HatchPlanRecord in
            guard let plan = plan(withID: id) else { throw BatchLifecycleError.planNotFound }
            guard plan.status.canTransition(to: .approvedReady) else {
                throw BatchLifecycleError.invalidTransition(from: plan.status, to: .approvedReady)
            }
            return plan
        }
        guard !plans.isEmpty else { return }

        let label = plans.count == 1 ? "batch \(plans[0].batchID)" : "\(plans.count) batches"
        let signature = try await ApprovalSignatureService.sign(as: currentUser.fullName,
                                                                reason: "Sign to authorise \(label) for setting.")

        for var plan in plans {
            plan.status = .approvedReady
            plan.reviewedBy = currentUser.fullName
            plan.reviewedAt = Date()
            plan.approvalSignature = signature
            plan.rejectionReason = nil
            planRepository.save(plan)

            appendSupervisorNotification(type: .approvalUpdate,
                                         title: "Plan for Batch \(plan.batchID) has been approved by \(currentUser.fullName).",
                                         message: "You can now execute the set.")
            appendManagerNotification(type: .approvalUpdate,
                                      title: "Batch \(plan.batchID) approved.",
                                      message: "Signed \(signature).")
        }
    }

    /// Manager: returns a plan to the supervisor with a mandatory reason.
    func rejectPlan(planID: String, reason: String) throws {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw BatchLifecycleError.invalidInput("Give the supervisor a reason so they can correct the plan.")
        }
        let plan = try transition(planID, to: .rejected, requiredRole: .manager, action: "reject production plans") { plan in
            plan.reviewedBy = currentUser.fullName
            plan.reviewedAt = Date()
            plan.rejectionReason = trimmed
            plan.approvalSignature = nil
        }

        appendSupervisorNotification(type: .approvalUpdate,
                                     title: "Batch \(plan.batchID) was rejected.",
                                     message: trimmed)
        appendManagerNotification(type: .systemMessage,
                                  title: "Batch \(plan.batchID) rejected.",
                                  message: trimmed)
    }

    /// Supervisor: records that eggs are physically set, then schedules the
    /// 21-day milestones in Calendar and as local reminders.
    @MainActor
    func executePlan(planID: String, addToCalendar: Bool, addReminders: Bool) async throws -> ScheduleOutcome {
        try requireRole(.supervisor, to: "execute sets")
        guard let approved = plan(withID: planID) else { throw BatchLifecycleError.planNotFound }
        guard approved.status.canTransition(to: .active) else {
            throw BatchLifecycleError.invalidTransition(from: approved.status, to: .active)
        }

        let setDate = Date()
        if addReminders {
            _ = await PushNotificationService.shared.requestAuthorizationAsync()
        }
        let outcome = await IncubationScheduler.shared.schedule(approved, setDate: setDate,
                                                                addToCalendar: addToCalendar, addReminders: addReminders)

        let plan = try transition(planID, to: .active, requiredRole: .supervisor, action: "execute sets") { plan in
            plan.executedAt = setDate
            plan.calendarEventIDs = outcome.calendarEventIDs
        }

        appendManagerNotification(type: .approvalUpdate,
                                  title: "Batch \(plan.batchID) set by \(currentUser.fullName).",
                                  message: "\(plan.requiredEggs.formatted()) eggs incubating. Hatch due \(plan.hatchDate).")
        return outcome
    }

    /// Supervisor: logs actual chicks pulled and closes the batch.
    func closeBatch(planID: String, actualChicks: Int, notes: String) throws {
        guard let current = plan(withID: planID) else { throw BatchLifecycleError.planNotFound }
        guard actualChicks >= 0, actualChicks <= current.requiredEggs else {
            throw BatchLifecycleError.invalidInput("Chicks hatched must be between 0 and the \(current.requiredEggs.formatted()) eggs set.")
        }

        let plan = try transition(planID, to: .completed, requiredRole: .supervisor, action: "close batches") { plan in
            plan.actualChicks = actualChicks
            plan.closedAt = Date()
            plan.closingNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        IncubationScheduler.shared.cancelReminders(for: plan)

        let rate = (plan.actualHatchability ?? 0).formatted(.percent.precision(.fractionLength(1)))
        appendManagerNotification(type: .weeklyReport,
                                  title: "Batch \(plan.batchID) closed at \(rate) hatchability.",
                                  message: "Performance report is ready to generate.")
    }

    private func requireRole(_ role: HatcheryRole, to action: String) throws {
        guard currentRole == role else {
            throw BatchLifecycleError.notPermitted(role: currentRole, action: action)
        }
    }

    private func transition(_ planID: String,
                            to next: BatchStatus,
                            requiredRole: HatcheryRole,
                            action: String,
                            mutate: (inout HatchPlanRecord) -> Void) throws -> HatchPlanRecord {
        try requireRole(requiredRole, to: action)
        guard var plan = plan(withID: planID) else { throw BatchLifecycleError.planNotFound }
        guard plan.status.canTransition(to: next) else {
            throw BatchLifecycleError.invalidTransition(from: plan.status, to: next)
        }
        mutate(&plan)
        plan.status = next
        planRepository.save(plan)
        return plan
    }

    /// Announces lifecycle events that happened on another device.
    private func handleRemoteStatusChange(_ plan: HatchPlanRecord, previous: BatchStatus?) {
        let notifications = PushNotificationService.shared
        switch (currentRole, plan.status) {
        case (.manager, .pendingReview):
            appendManagerNotification(type: .approvalUpdate,
                                      title: "Plan Approval Requested",
                                      message: "\(plan.createdBy) submitted \(plan.batchID) for \(plan.site.name).")
            notifications.scheduleApprovalNotification(batchID: plan.batchID, supervisorName: plan.createdBy)
        case (.manager, .completed):
            let rate = (plan.actualHatchability ?? 0).formatted(.percent.precision(.fractionLength(1)))
            notifications.scheduleLocalNotification(title: "Batch Closed",
                                                    body: "\(plan.batchID) closed at \(rate) hatchability.",
                                                    identifier: "closed_\(plan.id)")
        case (.supervisor, .approvedReady):
            notifications.scheduleLocalNotification(title: "Plan Approved",
                                                    body: "\(plan.batchID) was approved by \(plan.reviewedBy ?? "the manager"). Ready to set.",
                                                    identifier: "approved_\(plan.id)")
        case (.supervisor, .rejected):
            notifications.scheduleLocalNotification(title: "Plan Needs Changes",
                                                    body: "\(plan.batchID): \(plan.rejectionReason ?? "see manager notes").",
                                                    identifier: "rejected_\(plan.id)")
        default:
            break
        }
    }

    private func appendSupervisorNotification(type: NotificationType, title: String, message: String) {
        let notification = HatcheryNotification(
            type: type,
            title: title,
            message: message,
            timestamp: Date(),
            timeLabel: "Just now"
        )
        supervisorNotifications.insert(notification, at: 0)
        updateSupervisorUnreadCount()

        cacheSupervisorNotification(notification)
        persistSupervisorNotifications(supervisorNotifications)
        deliverSupervisorPushNotification(type: type, title: title, body: message, identifier: notification.id)
    }

    func loadSupervisorNotifications(completion: (() -> Void)? = nil) {
        syncService.fetchSupervisorNotifications { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    completion?()
                    return
                }

                switch result {
                case .success(let notifications):
                    if notifications.isEmpty {
                        self.restoreSupervisorNotificationsFromCacheOrSeed()
                    } else {
                        self.supervisorNotifications = notifications
                        self.cacheSupervisorNotifications(notifications)
                    }
                case .failure(let error):
                    print("Failed to fetch supervisor notifications: \(error.localizedDescription)")
                    self.restoreSupervisorNotificationsFromCacheOrSeed()
                }

                self.updateSupervisorUnreadCount()
                completion?()
            }
        }
    }

    private func restoreSupervisorNotificationsFromCacheOrSeed() {
        let cached = supervisorNotificationsFromCache()
        if !cached.isEmpty {
            supervisorNotifications = cached
            return
        }
        seedSupervisorNotifications()
    }

    private func seedSupervisorNotifications() {
        let samples = defaultSupervisorNotifications
        supervisorNotifications = samples
        cacheSupervisorNotifications(samples)
        syncService.syncSupervisorNotifications(notifications: samples) { _ in }
    }

    private var defaultSupervisorNotifications: [HatcheryNotification] {
        [
            HatcheryNotification(
                type: .criticalAlert,
                title: "Batch #B1024 is 24 hours from hatching. Resource allocation required.",
                message: "Critical resource needed",
                timestamp: Date().addingTimeInterval(-120),
                timeLabel: "2m ago"
            ),
            HatcheryNotification(
                type: .approvalUpdate,
                title: "Plan for Batch #B1030 has been Approved by Manager Aruni.",
                message: "Batch approved",
                timestamp: Date().addingTimeInterval(-3600),
                timeLabel: "1h ago"
            ),
            HatcheryNotification(
                type: .systemMessage,
                title: "Weekly hatchery report is ready for review.",
                message: "Report available",
                timestamp: Date().addingTimeInterval(-7200),
                timeLabel: "2h ago"
            )
        ]
    }

    private func cacheSupervisorNotification(_ notification: HatcheryNotification) {
        CoreDataManager.shared.saveNotification(
            id: notification.id,
            type: notification.type.rawValue,
            title: notification.title,
            message: notification.message,
            timestamp: notification.timestamp,
            timeLabel: notification.timeLabel,
            isRead: false,
            role: "supervisor"
        )
    }

    private func cacheSupervisorNotifications(_ notifications: [HatcheryNotification]) {
        notifications.forEach { cacheSupervisorNotification($0) }
    }

    private func supervisorNotificationsFromCache() -> [HatcheryNotification] {
        CoreDataManager.shared.fetchNotifications(forRole: "supervisor").compactMap { stored in
            guard let typeRaw = stored.type,
                  let type = NotificationType(rawValue: typeRaw),
                  let title = stored.title,
                  let message = stored.message,
                  let timestamp = stored.timestamp,
                  let timeLabel = stored.timeLabel else {
                return nil
            }

            return HatcheryNotification(
                type: type,
                title: title,
                message: message,
                timestamp: timestamp,
                timeLabel: timeLabel
            )
        }
    }

    private func persistSupervisorNotifications(_ notifications: [HatcheryNotification]) {
        syncService.syncSupervisorNotifications(notifications: notifications) { result in
            if case .failure(let error) = result {
                print("Failed to sync supervisor notifications: \(error.localizedDescription)")
            }
        }
    }

    private func deliverSupervisorPushNotification(
        type: NotificationType,
        title: String,
        body: String,
        identifier: String
    ) {
        guard supervisorPushNotificationsEnabled else { return }

        PushNotificationService.shared.scheduleLocalNotification(
            title: type.displayName,
            body: body.isEmpty ? title : body,
            identifier: identifier
        )
    }

    private var supervisorPushNotificationsEnabled: Bool {
        if UserDefaults.standard.object(forKey: "notificationsEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }

    private func updateSupervisorUnreadCount() {
        unreadSupervisorNotifCount = CoreDataManager.shared.unreadNotificationCount(forRole: "supervisor")
    }

    private func appendManagerNotification(type: NotificationType, title: String, message: String) {
        let notification = HatcheryNotification(type: type, title: title, message: message, timestamp: Date(), timeLabel: "Just now")
        managerNotifications.insert(notification, at: 0)
    }

    // MARK: - Firebase Sign In

    /// Signs in via Firebase Auth with email/password.
    func firebaseSignIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoadingAuth = true
        authErrorMessage = nil

        authService.signIn(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            self.isLoadingAuth = false

            switch result {
            case .success(let user):
                self.recordCredentials(email: email, name: user.displayName)
                // Save to Core Data
                CoreDataManager.shared.saveUserProfile(
                    uid: user.uid, email: email,
                    fullName: user.displayName ?? self.currentUser.fullName,
                    role: self.currentRole.rawValue
                )
                KeychainHelper.shared.saveUserSession(
                    uid: user.uid,
                    email: email,
                    name: user.displayName ?? self.currentUser.fullName,
                    role: self.currentRole.rawValue
                )
                completion(true)

            case .failure(let error):
                self.authErrorMessage = error.localizedDescription
                self.showAuthError = true
                completion(false)
            }
        }
    }

    // MARK: - Firebase Sign Up

    /// Creates a new Firebase Auth account.
    func firebaseSignUp(email: String, password: String, fullName: String, completion: @escaping (Bool) -> Void) {
        isLoadingAuth = true
        authErrorMessage = nil

        authService.signUp(email: email, password: password, fullName: fullName, role: currentRole) { [weak self] result in
            guard let self = self else { return }
            self.isLoadingAuth = false

            switch result {
            case .success(let user):
                self.recordCredentials(email: email, name: fullName)
                CoreDataManager.shared.saveUserProfile(
                    uid: user.uid, email: email,
                    fullName: fullName, role: self.currentRole.rawValue
                )
                completion(true)

            case .failure(let error):
                self.authErrorMessage = error.localizedDescription
                self.showAuthError = true
                completion(false)
            }
        }
    }

    // MARK: - Complete Authentication (Biometric / PIN)

    func completeAuthentication(usingFaceID: Bool, biometricAlreadyVerified: Bool = false) {
        preferredSecurityMethod = usingFaceID ? biometricService.biometricName : "PIN"
        currentUser = HatcheryUserProfile(
            fullName: currentUser.fullName,
            email: currentUser.email,
            role: currentRole,
            preferredSecurity: preferredSecurityMethod
        )

        if usingFaceID {
            if biometricAlreadyVerified {
                biometricService.enableBiometric()
                biometricsEnabled = true
                finishAuthentication()
            } else {
                biometricService.enableBiometricWithAuthentication(
                    reason: "Verify your identity to access HatchPlan Pro."
                ) { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        switch result {
                        case .success:
                            self.biometricsEnabled = true
                            self.finishAuthentication()
                        case .failure(let error):
                            // A declined biometric prompt must not lock the user out of a
                            // session they already authenticated for; fall back to PIN.
                            self.biometricsEnabled = false
                            self.preferredSecurityMethod = "PIN"
                            self.biometricErrorMessage = self.biometricService.localizedErrorMessage(from: error)
                            self.authErrorMessage = self.biometricErrorMessage
                            self.showAuthError = true
                            self.finishAuthentication()
                        }
                    }
                }
            }
        } else {
            finishAuthentication()
        }
    }

    private func finishAuthentication() {
        isAuthenticated = true
        // Firestore rules require a signed-in user; (re)attach now that we have one.
        planRepository.startListening()
        PushNotificationService.shared.requestAuthorization { _ in }
        refreshRoleNotifications()
    }

    private func refreshRoleNotifications() {
        switch currentRole {
        case .supervisor:
            loadSupervisorNotifications()
        case .manager:
            fetchManagerNotifications()
        }
    }

    // MARK: - Sign Out

    func signOut() {
        authService.signOut()
        isPINVerified = false
        isAuthenticated = false
        selectedTabIndex = 0
        authErrorMessage = nil
        showAuthError = false
        biometricErrorMessage = nil
        isUpdatingBiometrics = false
        biometricsEnabled = biometricService.isEnabled
        // A new sign-in should get the offer again, even if the last user skipped it.
        UserDefaults.standard.set(false, forKey: Self.biometricSetupDeclinedKey)
    }

    func syncCurrentState(completion: @escaping (String) -> Void) {
        syncService.syncDashboardSnapshot(role: currentRole, batches: batches, tasks: tasks) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.lastSyncSummary = "Synced to Firebase just now"
                    completion(self.lastSyncSummary)
                case .failure(let error):
                    self.lastSyncSummary = "Sync failed: \(error.localizedDescription)"
                    completion(self.lastSyncSummary)
                }
            }
        }
    }

    func fetchSupervisorNotifications() {
        loadSupervisorNotifications()
    }

    func fetchBatchInsights() {
        syncService.fetchBatchInsights { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let insights):
                    self.batchInsights = insights
                case .failure(let error):
                    print("Failed to fetch batch insights: \(error.localizedDescription)")
                }
            }
        }
    }

    func syncSupervisorData() {
        seedSupervisorNotifications()
        fetchBatchInsights()
        syncScheduleData()
        syncHatchDetails()
    }

    func syncScheduleData() {
        syncService.syncScheduledBatches(schedule: scheduledBatches, forecast: efficiencyForecast) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Schedule synced to Firebase")
                case .failure(let error):
                    print("Failed to sync schedule: \(error.localizedDescription)")
                }
            }
        }
    }

    /// The schedule is derived from hatch plans, which the repository keeps in
    /// sync with Firestore; this just recomputes relative dates ("TODAY").
    func fetchScheduledBatches() {
        rebuildSchedule(from: hatchPlans)
    }

    func syncHatchDetails() {
        guard !scheduledBatches.isEmpty else {
            return
        }

        for batch in scheduledBatches {
            let detail = detailSnapshot(for: batch)
            syncService.syncHatchDetail(detail) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.hatchDetailSnapshots[detail.batchID] = detail
                    case .failure(let error):
                        print("Failed to sync hatch details: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func fetchHatchDetail(for batchID: String) {
        syncService.fetchHatchDetail(batchID: batchID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let detail):
                    self.hatchDetailSnapshots[batchID] = detail
                case .failure(let error):
                    print("Failed to fetch hatch detail: \(error.localizedDescription)")
                }
            }
        }
    }

    func saveObservation(for batchID: String,
                         category: ObservationCategory,
                         note: String,
                         attachedPhotos: [String],
                         editingObservationID: String? = nil) {
        let currentSnapshot = hatchDetailSnapshots[batchID] ?? detailSnapshot(for: scheduledBatches.first(where: { $0.batchID == batchID }) ?? ScheduledBatch(batchID: batchID, breed: "Ross 308", eggs: 0, time: "00:00", timeOfDay: "AM", dateLabel: "TODAY", status: "", statusColor: .clear))

        var updatedObservations = currentSnapshot.observations
        let newObservation = SupervisorObservation(
            category: category.rawValue,
            note: note,
            authorName: currentUser.fullName,
            authorRole: currentUser.role.shortTitle.uppercased(),
            timeLabel: DateFormatter.observationTimestamp.string(from: Date()),
            attachedPhotos: attachedPhotos
        )

        if let editingObservationID,
           let index = updatedObservations.firstIndex(where: { $0.id == editingObservationID }) {
            updatedObservations[index] = newObservation
        } else {
            updatedObservations.insert(newObservation, at: 0)
        }

        let updatedSnapshot = HatchDetailSnapshot(
            batchID: currentSnapshot.batchID,
            productionUnit: currentSnapshot.productionUnit,
            breed: currentSnapshot.breed,
            criticalStatus: currentSnapshot.criticalStatus,
            incubationStage: currentSnapshot.incubationStage,
            imageName: currentSnapshot.imageName,
            liveConnected: currentSnapshot.liveConnected,
            sensors: currentSnapshot.sensors,
            metricTiles: currentSnapshot.metricTiles,
            operationalTimeline: currentSnapshot.operationalTimeline,
            sourceFlocks: currentSnapshot.sourceFlocks,
            biologicalTimeline: currentSnapshot.biologicalTimeline,
            observations: updatedObservations,
            eggSetDate: currentSnapshot.eggSetDate,
            hatchDate: currentSnapshot.hatchDate,
            co2Value: currentSnapshot.co2Value,
            co2Unit: currentSnapshot.co2Unit,
            co2Bars: currentSnapshot.co2Bars,
            eggsToSetLabel: currentSnapshot.eggsToSetLabel,
            shavalsNeededLabel: currentSnapshot.shavalsNeededLabel
        )

        hatchDetailSnapshots[batchID] = updatedSnapshot
        syncService.syncHatchDetail(updatedSnapshot) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.hatchDetailSnapshots[batchID] = updatedSnapshot
                case .failure(let error):
                    print("Failed to save observation: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Vision Kit Scanned Batch Methods

    func saveScannedBatch(_ batch: ScannedBatch) {
        scannedBatches.append(batch)
        syncService.syncScannedBatch(batch) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Scanned batch saved successfully: \(batch.batchID)")
                case .failure(let error):
                    print("Failed to save scanned batch: \(error.localizedDescription)")
                }
            }
        }
    }

    func fetchScannedBatches() {
        syncService.fetchScannedBatches { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let batches):
                    self.scannedBatches = batches
                case .failure(let error):
                    print("Failed to fetch scanned batches: \(error.localizedDescription)")
                }
            }
        }
    }

    init() {
        initializeHatchDetails()
        refreshVoiceOverStatus()

        planRepository.$plans
            .receive(on: DispatchQueue.main)
            .sink { [weak self] plans in
                self?.hatchPlans = plans
                self?.rebuildSchedule(from: plans)
            }
            .store(in: &cancellables)

        planRepository.$pendingSyncCount
            .receive(on: DispatchQueue.main)
            .assign(to: &$pendingSyncCount)

        planRepository.remoteStatusChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                self?.handleRemoteStatusChange(change.plan, previous: change.previous)
            }
            .store(in: &cancellables)

        planRepository.startListening()

        voiceOverObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshVoiceOverStatus()
        }

        // Listen for Firebase Auth state changes
        authStateHandle = authService.addAuthStateListener { [weak self] user in
            guard let self = self else { return }
            if let user = user {
                // User is signed in — restore session from Keychain
                let name = user.displayName ?? KeychainHelper.shared.read(forKey: KeychainHelper.userNameKey) ?? "User"
                let email = user.email ?? KeychainHelper.shared.read(forKey: KeychainHelper.userEmailKey) ?? ""
                self.currentUser = HatcheryUserProfile(
                    fullName: name, email: email,
                    role: self.currentRole,
                    preferredSecurity: self.preferredSecurityMethod
                )
                // Register FCM token
                PushNotificationService.shared.registerFCMToken(forUserUID: user.uid)
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            authService.removeAuthStateListener(handle)
        }
        if let observer = voiceOverObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Manager Notifications

    /// Fetches manager notifications from Firebase.
    func fetchManagerNotifications() {
        syncService.fetchManagerNotifications { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let notifications):
                    self?.managerNotifications = notifications
                    // Cache to Core Data
                    for notif in notifications {
                        CoreDataManager.shared.saveNotification(
                            id: notif.id, type: notif.type.rawValue,
                            title: notif.title, message: notif.message,
                            timestamp: notif.timestamp, timeLabel: notif.timeLabel,
                            isRead: false, role: "manager"
                        )
                    }
                case .failure(let error):
                    print("Failed to fetch manager notifications: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Syncs manager notifications to Firebase.
    func syncManagerNotifications() {
        let sampleNotifications: [HatcheryNotification] = [
            HatcheryNotification(type: .criticalAlert, title: "Batch B-08 humidity spike detected. Immediate review required.", message: "Humidity exceeded threshold", timestamp: Date().addingTimeInterval(-300), timeLabel: "5 min ago"),
            HatcheryNotification(type: .approvalUpdate, title: "Supervisor submitted Batch #C2-114 for approval.", message: "New approval request", timestamp: Date().addingTimeInterval(-1800), timeLabel: "30 min ago"),
            HatcheryNotification(type: .systemMessage, title: "Weekly production report is ready for download.", message: "Report available", timestamp: Date().addingTimeInterval(-7200), timeLabel: "2h ago"),
            HatcheryNotification(type: .weeklyReport, title: "Hatch rate improved by 3.1% this week across all facilities.", message: "Performance update", timestamp: Date().addingTimeInterval(-86400), timeLabel: "Yesterday")
        ]

        syncService.syncManagerNotifications(notifications: sampleNotifications) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.managerNotifications = sampleNotifications
                case .failure(let error):
                    print("Failed to sync manager notifications: \(error.localizedDescription)")
                }
            }
        }
    }
}

private extension DateFormatter {
    static let observationTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy • HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
