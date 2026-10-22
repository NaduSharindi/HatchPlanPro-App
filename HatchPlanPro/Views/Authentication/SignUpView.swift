//
//  SignUpView.swift
//  HatchPlanPro
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    let role: HatcheryRole

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var navigateToPIN = false
    @State private var showBiometricSetup = false
    @State private var localError: String?

    private var biometric: BiometricAuthService { BiometricAuthService.shared }

    private var accentColor: Color {
        role == .manager ? .figmaPrimary : .hatchGreen
    }

    private var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty &&
        password.count >= 6 && password == confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AuthBackButton()

                AuthHeader(
                    title: "Create Account",
                    subtitle: "Register as a \(role.shortTitle.lowercased()) to get started.",
                    accentColor: accentColor,
                    systemImage: "person.crop.circle.badge.plus"
                )
                .padding(.top, 8)

                VStack(spacing: 16) {
                    AuthTextField(
                        label: "Full name",
                        placeholder: "Your full name",
                        text: $fullName,
                        icon: "person.fill",
                        textContentType: .name
                    )

                    AuthTextField(
                        label: "Email address",
                        placeholder: "you@hatchery.com",
                        text: $email,
                        icon: "envelope.fill",
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )

                    AuthTextField(
                        label: "Password",
                        placeholder: "Minimum 6 characters",
                        text: $password,
                        icon: "lock.fill",
                        isSecure: true,
                        textContentType: .newPassword
                    )

                    AuthTextField(
                        label: "Confirm password",
                        placeholder: "Re-enter password",
                        text: $confirmPassword,
                        icon: "lock.rotation",
                        isSecure: true,
                        textContentType: .newPassword
                    )
                }
                .padding(.horizontal, 24)

                if let errorMsg = localError ?? (session.showAuthError ? session.authErrorMessage : nil) {
                    AuthErrorBanner(message: errorMsg)
                        .padding(.horizontal, 24)
                }

                AuthPrimaryButton(
                    title: "Create Account",
                    isLoading: session.isLoadingAuth,
                    isEnabled: isFormValid,
                    accentColor: accentColor,
                    action: signUp
                )
                .padding(.horizontal, 24)

                NavigationLink(destination: LoginView(role: role)) {
                    HStack(spacing: 4) {
                        Text("Already have an account?").foregroundColor(.secondary)
                        Text("Sign In").fontWeight(.bold).foregroundColor(accentColor)
                    }
                    .font(.subheadline)
                }
                .accessibilityLabel("Already have an account? Sign in")
            }
            .padding(.bottom, 32)
        }
        .background(AuthScreenBackground())
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToPIN) {
            PINAuthenticationView(
                role: role,
                subtitle: "Set up your \(role.shortTitle.lowercased()) PIN"
            )
        }
        .navigationDestination(isPresented: $showBiometricSetup) {
            BiometricSetupView(role: role)
        }
        .onDisappear {
            session.showAuthError = false
            session.authErrorMessage = nil
        }
    }

    private func signUp() {
        localError = nil
        guard !fullName.isEmpty else { localError = "Please enter your full name."; return }
        guard !email.isEmpty else { localError = "Please enter your email."; return }
        guard password.count >= 6 else { localError = "Password must be at least 6 characters."; return }
        guard password == confirmPassword else { localError = "Passwords do not match."; return }

        session.chooseRole(role)
        session.firebaseSignUp(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password,
            fullName: fullName
        ) { success in
            if success {
                if role == .supervisor {
                    if session.canEnableBiometrics && !session.biometricsEnabled {
                        showBiometricSetup = true
                    } else {
                        session.completeAuthentication(usingFaceID: false)
                    }
                } else {
                    navigateToPIN = true
                }
            }
        }
    }
}

#Preview {
    SignUpView(role: .manager)
        .environmentObject(AppSessionViewModel())
}
