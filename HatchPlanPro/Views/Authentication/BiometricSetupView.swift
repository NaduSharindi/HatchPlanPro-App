//
//  BiometricSetupView.swift
//  HatchPlanPro
//
//  Offered right after sign in / sign up so users can opt into biometrics
//  without hunting through settings. Skipping never blocks the dashboard.
//

import SwiftUI

struct BiometricSetupView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    let role: HatcheryRole

    @State private var errorMessage: String?
    @State private var isEnabling = false

    private let biometric = BiometricAuthService.shared

    private var accentColor: Color {
        role == .manager ? .figmaPrimary : .hatchGreen
    }

    private var subtitle: String {
        biometric.isBiometricAvailable
        ? "Use \(biometric.biometricName) for faster, secure access to your \(role.shortTitle.lowercased()) dashboard."
        : "You can turn this on later from Settings › Security once \(biometric.biometricName) is ready."
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            AuthHeader(
                title: "Enable \(biometric.biometricName)",
                subtitle: subtitle,
                accentColor: accentColor,
                systemImage: biometric.biometricIconName
            )

            if let errorMessage {
                AuthErrorBanner(message: errorMessage)
                    .padding(.horizontal, 24)
            } else if let reason = biometric.unavailableReason {
                BiometricNoticeBanner(message: reason,
                                      showsSettingsAction: biometric.shouldOfferSystemSettings) {
                    session.openSystemSettings()
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 14) {
                AuthPrimaryButton(
                    title: "Enable \(biometric.biometricName)",
                    isLoading: isEnabling,
                    isEnabled: biometric.isBiometricAvailable && !isEnabling,
                    accentColor: accentColor,
                    action: enableBiometrics
                )
                .padding(.horizontal, 24)

                Button(action: skip) {
                    Text(biometric.isBiometricAvailable ? "Skip for now" : "Continue to dashboard")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Skip biometric setup")
            }
            .padding(.bottom, 32)
        }
        .background(AuthScreenBackground())
        .navigationBarHidden(true)
    }

    private func enableBiometrics() {
        guard !isEnabling else { return }
        errorMessage = nil
        isEnabling = true

        session.setBiometricEnabled(true) { success in
            isEnabling = false
            if success {
                session.completeAuthentication(usingFaceID: true, biometricAlreadyVerified: true)
            } else {
                errorMessage = session.biometricErrorMessage
            }
        }
    }

    private func skip() {
        session.setBiometricEnabled(false)
        session.markBiometricSetupDeclined()
        session.completeAuthentication(usingFaceID: false)
    }
}
