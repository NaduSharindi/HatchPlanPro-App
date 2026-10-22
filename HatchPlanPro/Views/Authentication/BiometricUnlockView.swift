//
//  BiometricUnlockView.swift
//  HatchPlanPro
//
//  Shown when a Firebase session is still active and the user has opted
//  into biometric unlock after closing the app.
//

import SwiftUI

struct BiometricUnlockView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    @State private var errorMessage: String?
    @State private var isUnlocking = false

    private let biometric = BiometricAuthService.shared

    private var accentColor: Color {
        session.currentRole == .manager ? .figmaPrimary : .hatchGreen
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            AuthHeader(
                title: "Welcome Back",
                subtitle: "Use \(biometric.biometricName) to unlock your \(session.currentRole.shortTitle.lowercased()) session.",
                accentColor: accentColor,
                systemImage: biometric.biometricIconName
            )

            if let errorMessage {
                AuthErrorBanner(message: errorMessage)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 14) {
                AuthPrimaryButton(
                    title: "Unlock with \(biometric.biometricName)",
                    isLoading: isUnlocking,
                    isEnabled: biometric.isBiometricAvailable,
                    accentColor: accentColor,
                    action: unlock
                )
                .padding(.horizontal, 24)

                Button("Sign in with password instead") {
                    session.signOut()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            }
            .padding(.bottom, 36)
        }
        .background(AuthScreenBackground())
        .onAppear {
            session.restoreStoredSession()
            unlock()
        }
    }

    private func unlock() {
        guard !isUnlocking else { return }
        errorMessage = nil
        isUnlocking = true

        session.attemptBiometricUnlock { success, error in
            isUnlocking = false
            if success {
                errorMessage = nil
            } else if let error {
                errorMessage = biometric.localizedErrorMessage(from: error)
            }
        }
    }
}

#Preview {
    BiometricUnlockView()
        .environmentObject(AppSessionViewModel())
}
