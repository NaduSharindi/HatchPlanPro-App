//
//  BiometricAuthService.swift
//  HatchPlanPro
//

import Foundation
import LocalAuthentication

enum BiometricType: Equatable {
    case none
    case faceID
    case touchID

    var displayName: String {
        switch self {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Biometrics"
        }
    }

    var iconName: String {
        switch self {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock.fill"
        }
    }
}

/// Describes whether biometrics can be used right now, and why not when unavailable.
enum BiometricAvailability: Equatable {
    /// Hardware present and a face/finger is enrolled.
    case available
    /// Hardware present but the user has not enrolled in iOS Settings.
    case notEnrolled
    /// Too many failed attempts; requires device passcode to reset.
    case lockedOut
    /// No biometric hardware on this device.
    case notSupported

    var canAuthenticate: Bool { self == .available }
}

final class BiometricAuthService {

    static let shared = BiometricAuthService()
    private init() {}

    // MARK: - Capability

    /// The biometric hardware on this device.
    ///
    /// `LAContext.biometryType` is populated after any `canEvaluatePolicy` call,
    /// even when that call fails because nothing is enrolled. Reading it this way
    /// means we still show "Face ID" / "Touch ID" correctly before enrollment,
    /// instead of falling back to a generic label.
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        switch context.biometryType {
        case .faceID, .opticID:
            return .faceID
        case .touchID:
            return .touchID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    var availability: BiometricAvailability {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return .available
        }

        guard let code = error.flatMap({ LAError.Code(rawValue: $0.code) }) else {
            return .notSupported
        }

        switch code {
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockedOut
        default:
            return .notSupported
        }
    }

    /// Whether biometrics can be used for authentication right now.
    var isBiometricAvailable: Bool {
        availability.canAuthenticate
    }

    /// Whether the device has biometric hardware at all, enrolled or not.
    var isBiometricSupported: Bool {
        availability != .notSupported
    }

    /// True when `type` matches the hardware this device actually has.
    func isSupported(_ type: BiometricType) -> Bool {
        biometricType == type && isBiometricSupported
    }

    var biometricName: String { biometricType.displayName }

    var biometricIconName: String { biometricType.iconName }

    // MARK: - Authentication

    func authenticate(reason: String = "Log in to your HatchPlan account securely.",
                      completion: @escaping (Result<Void, Error>) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            let failure = error ?? NSError(
                domain: LAError.errorDomain,
                code: LAError.biometryNotAvailable.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Biometric authentication is not available on this device."]
            )
            DispatchQueue.main.async { completion(.failure(failure)) }
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(authError ?? NSError(
                        domain: LAError.errorDomain,
                        code: LAError.authenticationFailed.rawValue,
                        userInfo: [NSLocalizedDescriptionKey: "Biometric authentication failed."]
                    )))
                }
            }
        }
    }

    /// Runs the system biometric prompt and only persists the opt-in on success.
    func enableBiometricWithAuthentication(
        reason: String? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let promptReason = reason ?? "Confirm your identity to enable \(biometricName) sign-in."

        authenticate(reason: promptReason) { [weak self] result in
            switch result {
            case .success:
                self?.enableBiometric()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Preference

    func enableBiometric() {
        KeychainHelper.shared.setBiometricEnabled(true)
    }

    func disableBiometric() {
        KeychainHelper.shared.setBiometricEnabled(false)
    }

    var isEnabled: Bool {
        KeychainHelper.shared.isBiometricEnabled
    }

    // MARK: - Messaging

    /// Explains why biometrics can't be used, and whether iOS Settings can fix it.
    var unavailableReason: String? {
        switch availability {
        case .available:
            return nil
        case .notEnrolled:
            return "No \(biometricName) is set up on this device yet. Add one in iOS Settings, then turn it on here."
        case .lockedOut:
            return "\(biometricName) is locked after too many attempts. Unlock your device with its passcode, then try again."
        case .notSupported:
            return "This device does not support biometric authentication. Use your PIN instead."
        }
    }

    /// Whether pointing the user at iOS Settings would resolve the current problem.
    var shouldOfferSystemSettings: Bool {
        availability == .notEnrolled
    }

    func localizedErrorMessage(from error: Error) -> String {
        let nsError = error as NSError

        guard nsError.domain == LAError.errorDomain,
              let code = LAError.Code(rawValue: nsError.code) else {
            return nsError.localizedDescription
        }

        switch code {
        case .biometryNotAvailable:
            return "This device does not support biometric authentication."
        case .biometryNotEnrolled:
            return "No \(biometricName) is set up. Add one in iOS Settings, then try again."
        case .biometryLockout:
            return "\(biometricName) is locked. Unlock your device with its passcode, then try again."
        case .authenticationFailed:
            return "\(biometricName) could not verify you. Please try again."
        case .userCancel, .systemCancel, .appCancel:
            return "\(biometricName) was cancelled."
        case .userFallback:
            return "Enter your PIN to continue."
        case .passcodeNotSet:
            return "Set a device passcode before enabling \(biometricName)."
        default:
            return nsError.localizedDescription
        }
    }
}
