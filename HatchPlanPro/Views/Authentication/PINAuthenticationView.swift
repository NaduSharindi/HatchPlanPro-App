//
//  PINAuthenticationView.swift
//  HatchPlanPro
//

import SwiftUI

struct PINAuthenticationView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel = AuthViewModel()

    let role: HatcheryRole
    let subtitle: String

    @State private var isFirstTimePINSetup = false
    @State private var navigateToBiometricSetup = false

    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private let keypadButtons = [
        "1", "2", "3",
        "4", "5", "6",
        "7", "8", "9",
        "faceid", "0", "delete"
    ]

    private var accentColor: Color {
        role == .manager ? .figmaPrimary : .hatchGreen
    }

    private var biometric: BiometricAuthService { BiometricAuthService.shared }

    var body: some View {
        VStack(spacing: 24) {
            AuthBackButton()

            AuthHeader(
                title: role.shortTitle,
                subtitle: isFirstTimePINSetup ? "Create a 4-digit PIN" : subtitle,
                accentColor: accentColor,
                systemImage: "lock.shield.fill"
            )
            .padding(.top, 4)

            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.pin.count ? Color.figmaTextDark : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .scaleEffect(index < viewModel.pin.count ? 1.2 : 1.0)
                        .animation(.spring(response: 0.2), value: viewModel.pin.count)
                }
            }
            .padding(.vertical, 20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(viewModel.pin.count) of 4 digits entered")

            if viewModel.showError, let errorMsg = viewModel.errorMessage {
                AuthErrorBanner(message: errorMsg)
                    .padding(.horizontal, 24)
            }

            Spacer()

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(keypadButtons, id: \.self) { button in
                    Button {
                        handleKeyPress(button)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.05))
                                .frame(width: 75, height: 75)

                            if button == "faceid" {
                                Image(systemName: biometric.biometricIconName)
                                    .font(.title)
                            } else if button == "delete" {
                                Image(systemName: "delete.backward")
                                    .font(.title)
                            } else {
                                Text(button)
                                    .font(.title)
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(.figmaTextDark)
                    }
                    .disabled(faceIDButtonDisabled(button))
                    .accessibilityLabel(
                        button == "faceid" ? biometric.biometricName :
                        (button == "delete" ? "Delete" : "Digit \(button)")
                    )
                }
            }
            .padding(.horizontal, 40)

            if biometric.isBiometricAvailable {
                if biometric.isEnabled {
                    Button(action: attemptBiometricLogin) {
                        Text("Use \(biometric.biometricName) instead")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(accentColor)
                            .padding(.top, 20)
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel("Use \(biometric.biometricName) instead of PIN")
                } else {
                    // Enrollment is offered only after the PIN succeeds, so biometrics
                    // can never be used to bypass the app's own PIN gate.
                    Text("Enter your PIN once — you can turn on \(biometric.biometricName) right after.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                }
            }

            Spacer()
        }
        .background(AuthScreenBackground())
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToBiometricSetup) {
            BiometricSetupView(role: role)
        }
        .onAppear {
            isFirstTimePINSetup = !KeychainHelper.shared.hasPIN
            if !isFirstTimePINSetup && biometric.isEnabled {
                attemptBiometricLogin()
            }
        }
        .onChange(of: viewModel.isAuthenticated) { _, authenticated in
            guard authenticated else { return }
            if isFirstTimePINSetup || session.shouldOfferBiometricEnrollment {
                navigateToBiometricSetup = true
            } else {
                session.completeAuthentication(usingFaceID: false)
            }
        }
    }

    private func faceIDButtonDisabled(_ button: String) -> Bool {
        if button == "faceid" {
            return !biometric.isBiometricAvailable || !biometric.isEnabled || viewModel.isLoading
        }
        if button == "delete" {
            return viewModel.pin.isEmpty
        }
        return false
    }

    private func handleKeyPress(_ button: String) {
        if button == "delete" {
            viewModel.deleteDigit()
        } else if button == "faceid" {
            attemptBiometricLogin()
        } else {
            viewModel.enterDigit(button)
        }
    }

    private func attemptBiometricLogin() {
        viewModel.authenticateWithBiometrics { success in
            if success {
                session.completeAuthentication(usingFaceID: true, biometricAlreadyVerified: true)
            }
        }
    }
}

#Preview {
    PINAuthenticationView(role: .manager, subtitle: "Enter your manager PIN")
        .environmentObject(AppSessionViewModel())
}
