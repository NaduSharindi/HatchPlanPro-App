//
//  ApprovalSignatureService.swift
//  HatchPlanPro
//
//  Gates manager authorisation behind device-owner authentication. Face ID or
//  Touch ID is used when enrolled, with the device passcode as fallback; the
//  resulting signature is stored on the batch for the audit trail.
//

import Foundation
import LocalAuthentication

enum ApprovalSignatureService {
    static func sign(as signer: String, reason: String) async throws -> String {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var policyError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &policyError) else {
            throw BatchLifecycleError.signatureFailed(
                "Set up Face ID, Touch ID or a device passcode to sign approvals. In the Simulator, choose Features › Face ID › Enrolled."
            )
        }

        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            throw BatchLifecycleError.signatureFailed("Signature not applied: \(error.localizedDescription)")
        }

        // LocalAuthentication does not report whether the passcode fallback was
        // used, so the signature records what the device offered.
        let method: String
        switch context.biometryType {
        case .faceID: method = "Face ID/Passcode"
        case .touchID: method = "Touch ID/Passcode"
        case .opticID: method = "Optic ID/Passcode"
        default: method = "Device Passcode"
        }
        return "\(signer) • \(method) • \(Date().formatted(.iso8601))"
    }
}
