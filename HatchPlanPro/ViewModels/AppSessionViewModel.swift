//
//  AppSessionViewModel.swift
//  HatchPlanPro
//
//  App-wide session: the signed-in user and role, authentication and
//  biometrics, accessibility preferences, and the batch lifecycle
//  (Planning → Verification → Documentation → Execution → Closing).
//

import Foundation
import Combine
import SwiftUI
import UIKit
import FirebaseAuth
import UserNotifications

final class AppSessionViewModel: ObservableObject {
    @Published var currentRole: HatcheryRole = .manager
    @Published var currentUser = HatcheryUserProfile(fullName: "", email: "", role: .manager, preferredSecurity: "Password")
    @Published var isAuthenticated = false
    @Published var preferredSecurityMethod = "Password"
    @Published var selectedTabIndex = 0
    @Published var accessibilityTextScale: Double = 1.0
    @Published private(set) var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    @Published var biometricsEnabled: Bool = BiometricAuthService.shared.isEnabled
    @Published var isUpdatingBiometrics = false
    @Published var biometricErrorMessage: String?

    // MARK: Auth state
    @Published var isLoadingAuth = false
    @Published var authErrorMessage: String?
    @Published var showAuthError = false

    // MARK: Batch state
    @Published var hatchPlans: [HatchPlanRecord] = []
    @Published var scheduledBatches: [ScheduledBatch] = []
    @Published var efficiencyForecast = EfficiencyForecast(title: "No batches incubating", percentage: 0)
    /// Batches saved on this device that Firestore has not acknowledged yet.
    @Published private(set) var pendingSyncCount = 0
    @Published private(set) var lastSyncError: String?

    // MARK: Notifications
    @Published private(set) var activityItems: [ActivityItem] = []
    @Published private(set) var unreadActivityCount = 0

    /// Batch opened from Spotlight or a notification tap.
    @Published var deepLinkPlanID: String?

    private let authService = FirebaseAuthService.shared
    private let biometricService = BiometricAuthService.shared
    private let planRepository = HatchPlanRepository.shared
    private var cancellables = Set<AnyCancellable>()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var voiceOverObserver: NSObjectProtocol?
    private var readActivityIDs: Set<String> = []

    init() {
        refreshVoiceOverStatus()

        planRepository.$plans
            .receive(on: DispatchQueue.main)
            .sink { [weak self] plans in
                guard let self else { return }
                self.hatchPlans = plans
                self.rebuildSchedule(from: plans)
                self.rebuildActivity()
                SpotlightIndexer.index(plans)
            }
            .store(in: &cancellables)

        planRepository.$pendingSyncCount
            .receive(on: DispatchQueue.main)
            .assign(to: &$pendingSyncCount)

        planRepository.$lastSyncError
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastSyncError)

        planRepository.remoteStatusChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                self?.announceRemoteStatusChange(change.plan)
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

        authStateHandle = authService.addAuthStateListener { [weak self] user in
            guard let self, let user else { return }
            if self.currentUser.fullName.isEmpty { self.currentUser.fullName = user.displayName ?? "" }
            if self.currentUser.email.isEmpty { self.currentUser.email = user.email ?? "" }
            self.currentUser.uid = user.uid
            PushNotificationService.shared.registerFCMToken(forUserUID: user.uid)
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

    // MARK: - Accessibility

    var preferredDynamicTypeSize: DynamicTypeSize {
        switch accessibilityTextScale {
        case ..<0.9: return .xSmall
        case ..<1.0: return .small
        case ..<1.1: return .medium
        case ..<1.2: return .large
        case ..<1.3: return .xLarge
        case ..<1.4: return .xxLarge
        default: return .xxxLarge
        }
    }

    func setAccessibilityTextScale(_ scale: Double) {
        accessibilityTextScale = min(max(scale, 0.85), 1.45)
    }

    func refreshVoiceOverStatus() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    }

    var voiceOverToggleBinding: Binding<Bool> {
        Binding(
            get: { self.isVoiceOverRunning },
            set: { _ in self.openSystemSettings() }
        )
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Biometrics

    var biometricType: BiometricType { biometricService.biometricType }
    var biometricName: String { biometricService.biometricName }
    var canEnableBiometrics: Bool { biometricService.isBiometricAvailable }

    /// Offer biometrics after sign-in unless the user already said "Skip".
    var shouldOfferBiometricEnrollment: Bool {
        biometricService.isBiometricAvailable && !biometricService.isEnabled && !hasDeclinedBiometricSetup
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

    /// Enabling always runs the real system prompt first, so the stored
    /// preference can never claim biometrics work when the user never verified.
    func setBiometricEnabled(_ enabled: Bool, completion: ((Bool) -> Void)? = nil) {
        biometricErrorMessage = nil

        guard enabled else {
            biometricService.disableBiometric()
            biometricsEnabled = false
            currentUser.preferredSecurity = "Password"
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
                self.currentUser.preferredSecurity = self.biometricService.biometricName
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

    var canUseBiometricSignIn: Bool {
        authService.isSignedIn && biometricService.isEnabled && biometricService.isBiometricAvailable
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

    // MARK: - Sign In / Sign Up

    func chooseRole(_ role: HatcheryRole) {
        currentRole = role
        currentUser.role = role
    }

    /// Restores the last signed-in profile from the Keychain and local cache.
    func restoreStoredSession() {
        guard let email = KeychainHelper.shared.read(forKey: KeychainHelper.userEmailKey),
              let name = KeychainHelper.shared.read(forKey: KeychainHelper.userNameKey),
              let roleRaw = KeychainHelper.shared.read(forKey: KeychainHelper.userRoleKey),
              let role = HatcheryRole(rawValue: roleRaw) else {
            return
        }

        currentRole = role
        let uid = KeychainHelper.shared.read(forKey: KeychainHelper.userUIDKey)
        if let uid,
           let data = UserDefaults.standard.data(forKey: Self.profileCacheKey(uid)),
           let cached = try? JSONDecoder().decode(HatcheryUserProfile.self, from: data) {
            currentUser = cached
        } else {
            currentUser = HatcheryUserProfile(fullName: name, email: email, role: role, preferredSecurity: "Password", uid: uid)
        }
        currentUser.preferredSecurity = biometricService.isEnabled ? biometricService.biometricName : "Password"
        biometricsEnabled = biometricService.isEnabled
        loadReadActivity()
    }

    func firebaseSignIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoadingAuth = true
        authErrorMessage = nil
        showAuthError = false

        let chosenRole = currentRole
        authService.signIn(email: email, password: password) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let user):
                Task { @MainActor in
                    do {
                        let profile = try await self.resolveProfile(for: user, email: email, chosenRole: chosenRole)
                        self.adoptProfile(profile)
                        self.isLoadingAuth = false
                        completion(true)
                    } catch {
                        self.authService.signOut()
                        self.isLoadingAuth = false
                        self.authErrorMessage = error.localizedDescription
                        self.showAuthError = true
                        completion(false)
                    }
                }
            case .failure(let error):
                self.isLoadingAuth = false
                self.authErrorMessage = error.localizedDescription
                self.showAuthError = true
                completion(false)
            }
        }
    }

    func firebaseSignUp(email: String, password: String, fullName: String,
                        siteID: String = HatcherySite.all[0].id,
                        completion: @escaping (Bool) -> Void) {
        isLoadingAuth = true
        authErrorMessage = nil
        showAuthError = false

        authService.signUp(email: email, password: password, fullName: fullName, role: currentRole) { [weak self] result in
            guard let self else { return }
            self.isLoadingAuth = false
            switch result {
            case .success(let user):
                let profile = HatcheryUserProfile(fullName: fullName, email: email, role: self.currentRole,
                                                  preferredSecurity: "Password", uid: user.uid, siteID: siteID)
                self.adoptProfile(profile)
                Task { try? await self.authService.saveProfile(profile) }
                completion(true)
            case .failure(let error):
                self.authErrorMessage = error.localizedDescription
                self.showAuthError = true
                completion(false)
            }
        }
    }

    /// The role is a property of the account: an account registered as a
    /// supervisor cannot open the manager dashboard and vice versa. Accounts
    /// without a profile (e.g. created in the console) take the chosen role.
    @MainActor
    private func resolveProfile(for user: User, email: String, chosenRole: HatcheryRole) async throws -> HatcheryUserProfile {
        if let stored = try await authService.loadProfile(uid: user.uid, email: email) {
            guard stored.role == chosenRole else {
                throw BatchLifecycleError.invalidInput(
                    "This account is registered as a \(stored.role.rawValue). Go back and choose \(stored.role.shortTitle) to sign in."
                )
            }
            return stored
        }
        let profile = HatcheryUserProfile(
            fullName: user.displayName ?? email.components(separatedBy: "@").first ?? "User",
            email: email,
            role: chosenRole,
            preferredSecurity: "Password",
            uid: user.uid
        )
        try await authService.saveProfile(profile)
        return profile
    }

    /// Makes a profile the current user and caches it for offline launches.
    private func adoptProfile(_ profile: HatcheryUserProfile) {
        var profile = profile
        profile.preferredSecurity = biometricService.isEnabled ? biometricService.biometricName : "Password"
        currentRole = profile.role
        currentUser = profile
        if let uid = profile.uid {
            KeychainHelper.shared.saveUserSession(uid: uid, email: profile.email, name: profile.fullName, role: profile.role.rawValue)
            CoreDataManager.shared.saveUserProfile(uid: uid, email: profile.email, fullName: profile.fullName, role: profile.role.rawValue)
            if let data = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(data, forKey: Self.profileCacheKey(uid))
            }
        }
        loadReadActivity()
    }

    private static func profileCacheKey(_ uid: String) -> String { "hatchplan.profile.\(uid)" }

    /// Saves edits from the profile screen to Firestore and the local cache.
    @MainActor
    func updateProfile(_ profile: HatcheryUserProfile) async throws {
        var profile = profile
        profile.uid = profile.uid ?? authService.currentUser?.uid
        try await authService.saveProfile(profile)
        adoptProfile(profile)
    }

    @MainActor
    func changePassword(current: String, new: String) async throws {
        try await authService.changePassword(current: current, new: new)
    }

    func completeAuthentication(usingFaceID: Bool, biometricAlreadyVerified: Bool = false) {
        preferredSecurityMethod = usingFaceID ? biometricService.biometricName : "Password"
        currentUser.role = currentRole
        currentUser.preferredSecurity = preferredSecurityMethod

        guard usingFaceID else {
            finishAuthentication()
            return
        }

        if biometricAlreadyVerified {
            biometricService.enableBiometric()
            biometricsEnabled = true
            finishAuthentication()
            return
        }

        biometricService.enableBiometricWithAuthentication(reason: "Verify your identity to access HatchPlan Pro.") { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.biometricsEnabled = true
                case .failure(let error):
                    // A declined prompt must not lock out a session that already
                    // authenticated with a password.
                    self.biometricsEnabled = false
                    self.preferredSecurityMethod = "Password"
                    self.biometricErrorMessage = self.biometricService.localizedErrorMessage(from: error)
                }
                self.finishAuthentication()
            }
        }
    }

    private func finishAuthentication() {
        isAuthenticated = true
        loadReadActivity()
        // Firestore rules require a signed-in user; (re)attach now that we have one.
        planRepository.startListening()
        ObservationRepository.shared.flushPendingWrites()
        PushNotificationService.shared.requestAuthorization { _ in }
    }

    func signOut() {
        authService.signOut()
        isAuthenticated = false
        selectedTabIndex = 0
        authErrorMessage = nil
        showAuthError = false
        biometricErrorMessage = nil
        isUpdatingBiometrics = false
        biometricsEnabled = biometricService.isEnabled
        deepLinkPlanID = nil
        // A new sign-in should get the offer again, even if the last user skipped it.
        UserDefaults.standard.set(false, forKey: Self.biometricSetupDeclinedKey)
    }

    // MARK: - Plan Queries

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

    var todayScheduledBatches: [ScheduledBatch] {
        scheduledBatches.filter { $0.dateLabel.uppercased().hasPrefix("TODAY") }
    }

    /// The schedule is derived from plans; this recomputes relative labels ("TODAY").
    func fetchScheduledBatches() {
        rebuildSchedule(from: hatchPlans)
    }

    // MARK: - Batch Lifecycle

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
        guard !draft.customerName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw BatchLifecycleError.invalidInput("Enter the customer this order is for.")
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
        Haptics.notify(.success)
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
        }
        Haptics.notify(.success)
    }

    /// Manager: returns a plan to the supervisor with a mandatory reason.
    func rejectPlan(planID: String, reason: String) throws {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw BatchLifecycleError.invalidInput("Give the supervisor a reason so they can correct the plan.")
        }
        try transition(planID, to: .rejected, requiredRole: .manager, action: "reject production plans") { plan in
            plan.reviewedBy = currentUser.fullName
            plan.reviewedAt = Date()
            plan.rejectionReason = trimmed
            plan.approvalSignature = nil
        }
        Haptics.notify(.warning)
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
        try transition(planID, to: .active, requiredRole: .supervisor, action: "execute sets") { plan in
            plan.executedAt = setDate
            plan.calendarEventIDs = outcome.calendarEventIDs
        }
        Haptics.notify(.success)
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
        Haptics.notify(.success)
    }

    private func requireRole(_ role: HatcheryRole, to action: String) throws {
        guard currentRole == role else {
            throw BatchLifecycleError.notPermitted(role: currentRole, action: action)
        }
    }

    @discardableResult
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

    // MARK: - Observations

    func observations(for planID: String) -> [BatchObservation] {
        ObservationRepository.shared.observations(for: planID)
    }

    func saveObservation(_ observation: BatchObservation) throws {
        try requireRole(.supervisor, to: "record observations")
        guard !observation.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BatchLifecycleError.invalidInput("Describe what you observed before saving.")
        }
        ObservationRepository.shared.save(observation)
        Haptics.notify(.success)
    }

    func canEdit(_ observation: BatchObservation) -> Bool {
        currentRole == .supervisor && (observation.authorUID == nil || observation.authorUID == currentUser.uid)
    }

    func newObservation(for planID: String) -> BatchObservation {
        BatchObservation(planID: planID, category: .shellQuality, note: "",
                         authorName: currentUser.fullName, authorRole: currentUser.displayTitle.uppercased(),
                         authorUID: currentUser.uid)
    }

    // MARK: - Activity Feed

    private var readActivityKey: String {
        "hatchplan.readActivity.\(currentUser.uid ?? currentRole.rawValue).\(currentRole.rawValue)"
    }

    private func loadReadActivity() {
        readActivityIDs = Set(UserDefaults.standard.stringArray(forKey: readActivityKey) ?? [])
        rebuildActivity()
    }

    private func rebuildActivity() {
        let items = ActivityFeedBuilder.items(for: currentRole, plans: hatchPlans)
        if isAuthenticated, !items.isEmpty, UserDefaults.standard.stringArray(forKey: readActivityKey) == nil {
            // First time this user opens the feed on this device: only the last day counts as new.
            let cutoff = Date().addingTimeInterval(-86_400)
            readActivityIDs.formUnion(items.filter { $0.date < cutoff }.map(\.id))
            UserDefaults.standard.set(Array(readActivityIDs), forKey: readActivityKey)
        }
        activityItems = items.map { item in
            var item = item
            item.isRead = readActivityIDs.contains(item.id)
            return item
        }
        unreadActivityCount = activityItems.filter { !$0.isRead }.count
        UNUserNotificationCenter.current().setBadgeCount(isAuthenticated ? unreadActivityCount : 0)
    }

    func markActivityRead(_ id: String) {
        guard !readActivityIDs.contains(id) else { return }
        readActivityIDs.insert(id)
        UserDefaults.standard.set(Array(readActivityIDs), forKey: readActivityKey)
        rebuildActivity()
    }

    func markAllActivityRead() {
        readActivityIDs.formUnion(activityItems.map(\.id))
        UserDefaults.standard.set(Array(readActivityIDs), forKey: readActivityKey)
        rebuildActivity()
    }

    /// Banner for lifecycle events that happened on another device.
    private func announceRemoteStatusChange(_ plan: HatchPlanRecord) {
        guard isAuthenticated, UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true else { return }
        let notifications = PushNotificationService.shared
        switch (currentRole, plan.status) {
        case (.manager, .pendingReview):
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

    // MARK: - Schedule

    /// Each approved or incubating batch contributes its next milestone.
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
}
