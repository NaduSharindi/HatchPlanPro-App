//
//  LoginView.swift
//  HatchPlanPro
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    let role: HatcheryRole

    @State private var email = ""
    @State private var password = ""
    @State private var navigateToPIN = false

    private var accentColor: Color {
        role == .manager ? .figmaPrimary : .hatchGreen
    }

    private var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AuthBackButton()

                AuthHeader(
                    title: "Welcome Back",
                    subtitle: "Sign in to your \(role.shortTitle.lowercased()) account.",
                    accentColor: accentColor,
                    systemImage: role.displaySymbol
                )
                .padding(.top, 8)

                VStack(spacing: 16) {
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
                        placeholder: "Enter your password",
                        text: $password,
                        icon: "lock.fill",
                        isSecure: true,
                        textContentType: .password
                    )
                }
                .padding(.horizontal, 24)

                if session.showAuthError, let errorMsg = session.authErrorMessage {
                    AuthErrorBanner(message: errorMsg)
                        .padding(.horizontal, 24)
                }

                AuthPrimaryButton(
                    title: "Sign In",
                    isLoading: session.isLoadingAuth,
                    isEnabled: canSignIn,
                    accentColor: accentColor,
                    action: signIn
                )
                .padding(.horizontal, 24)

                NavigationLink(
                    destination: PINAuthenticationView(
                        role: role,
                        subtitle: "Create a 4-digit PIN for quick access"
                    ),
                    isActive: $navigateToPIN
                ) {
                    EmptyView()
                }

                NavigationLink(destination: SignUpView(role: role)) {
                    Text("Need an account? Create one")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(accentColor)
                }
                .accessibilityLabel("Create account")
            }
            .padding(.bottom, 32)
        }
        .background(AuthScreenBackground())
        .navigationBarHidden(true)
        .onDisappear {
            session.showAuthError = false
            session.authErrorMessage = nil
        }
    }

    private func signIn() {
        session.chooseRole(role)
        session.firebaseSignIn(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password
        ) { success in
            if success {
                navigateToPIN = true
            }
        }
    }
}
