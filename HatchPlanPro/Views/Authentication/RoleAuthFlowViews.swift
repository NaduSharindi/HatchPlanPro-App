//
//  RoleAuthFlowViews.swift
//  HatchPlanPro
//
//  One onboarding → sign in / sign up → biometric setup flow, shared by the
//  supervisor and manager roles.
//

import SwiftUI

/// Role introduction shown the first time a role is chosen on this device;
/// afterwards the role button goes straight to sign in.
struct RoleOnboardingView: View {
    let role: HatcheryRole
    @State private var goToLogin = false
    @State private var hasSeen: Bool

    init(role: HatcheryRole) {
        self.role = role
        _hasSeen = State(initialValue: UserDefaults.standard.bool(forKey: Self.seenKey(role)))
    }

    private static func seenKey(_ role: HatcheryRole) -> String { "hatchplan.seenOnboarding.\(role.shortTitle)" }

    var body: some View {
        if hasSeen {
            RoleLoginView(role: role)
        } else {
            ZStack {
                AuthScreenBackground()
                OnboardingFlowView(
                    pages: AppOnboardingContent.pages(for: role),
                    accentColor: .hatchGreen,
                    finishButtonTitle: "Continue to Sign In",
                    onSkip: finish,
                    onFinish: finish
                )
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $goToLogin) {
                RoleLoginView(role: role)
            }
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: Self.seenKey(role))
        goToLogin = true
    }
}

// MARK: - Sign In

struct RoleLoginView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    let role: HatcheryRole

    @State private var email = ""
    @State private var password = ""
    @State private var showBiometricSetup = false
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }
    private let biometric = BiometricAuthService.shared

    private var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !session.isLoadingAuth
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AuthBackButton()

                VStack(spacing: 8) {
                    AppLogoView(size: 76)
                    Text("HatchPlan Pro")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.hatchGreenDeep)
                    Text("\(role.shortTitle.uppercased()) SIGN IN")
                        .font(.caption.weight(.semibold))
                        .tracking(3)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 16) {
                    AuthTextField(label: "Email address", placeholder: "you@primahatchery.com", text: $email,
                                  icon: "envelope.fill", keyboardType: .emailAddress, textContentType: .username)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                    AuthTextField(label: "Password", placeholder: "Enter your password", text: $password,
                                  icon: "lock.fill", isSecure: true, textContentType: .password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { if canSignIn { signIn() } }
                }
                .padding(.horizontal, 24)

                if session.showAuthError, let message = session.authErrorMessage {
                    AuthErrorBanner(message: message).padding(.horizontal, 24)
                }

                AuthPrimaryButton(title: "Sign In", isLoading: session.isLoadingAuth, isEnabled: canSignIn,
                                  accentColor: .hatchGreenDeep, action: signIn)
                    .padding(.horizontal, 24)

                if session.canUseBiometricSignIn && session.currentRole == role {
                    Button(action: unlockWithBiometrics) {
                        Label("Unlock with \(biometric.biometricName)", systemImage: biometric.biometricIconName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.hatchGreen)
                    }
                }

                VStack(spacing: 14) {
                    NavigationLink(destination: ForgotPasswordView(prefilledEmail: email)) {
                        Text("Forgot Password?").foregroundColor(.secondary)
                    }
                    NavigationLink(destination: RoleSignUpView(role: role)) {
                        HStack(spacing: 4) {
                            Text("Don't have an account?").foregroundColor(.secondary)
                            Text("Sign Up").fontWeight(.bold).foregroundColor(.hatchGreen)
                        }
                    }
                }
                .font(.subheadline)

                Text("SECURE INDUSTRIAL ACCESS")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.5)
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 12)
            }
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AuthScreenBackground())
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showBiometricSetup) {
            BiometricSetupView(role: role)
        }
        .onAppear {
            session.chooseRole(role)
            if email.isEmpty, let stored = KeychainHelper.shared.read(forKey: KeychainHelper.userEmailKey),
               KeychainHelper.shared.read(forKey: KeychainHelper.userRoleKey) == role.rawValue {
                email = stored
            }
        }
        .onDisappear {
            session.showAuthError = false
            session.authErrorMessage = nil
        }
    }

    private func signIn() {
        focusedField = nil
        session.chooseRole(role)
        session.firebaseSignIn(email: email.trimmingCharacters(in: .whitespaces), password: password) { success in
            guard success else { return }
            if session.shouldOfferBiometricEnrollment {
                showBiometricSetup = true
            } else {
                session.completeAuthentication(usingFaceID: false)
            }
        }
    }

    private func unlockWithBiometrics() {
        session.attemptBiometricUnlock { success, error in
            if !success, let error {
                session.authErrorMessage = biometric.localizedErrorMessage(from: error)
                session.showAuthError = true
            }
        }
    }
}

// MARK: - Sign Up

struct RoleSignUpView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    let role: HatcheryRole

    @State private var fullName = ""
    @State private var email = ""
    @State private var siteID = HatcherySite.all[0].id
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var acceptedTerms = false
    @State private var localError: String?
    @State private var showBiometricSetup = false
    @State private var showTerms = false

    private var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
            && email.contains("@")
            && password.count >= 8
            && password == confirmPassword
            && acceptedTerms
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AuthBackButton()

                VStack(spacing: 8) {
                    AppLogoView(size: 64)
                    Text("Digital Agronomist")
                        .font(.headline)
                        .foregroundColor(.hatchGreenDeep)
                    Text("Join the network of professional hatchery \(role == .manager ? "managers" : "supervisors") and precision farmers.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                sectionTitle("PERSONAL INFORMATION")
                AuthTextField(label: "Full Name", placeholder: "Nadunika Sharindi", text: $fullName,
                              icon: "person.fill", textContentType: .name)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Professional Role").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                        Text(role.rawValue).font(.body.weight(.semibold))
                    }
                    Spacer()
                    Image(systemName: role.displaySymbol).foregroundColor(.hatchGreen)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#E9E9EE")))

                HStack {
                    Text("Hatchery Location").font(.subheadline)
                    Spacer()
                    Picker("Hatchery Location", selection: $siteID) {
                        ForEach(HatcherySite.all) { Text($0.name).tag($0.id) }
                    }
                    .labelsHidden()
                    .tint(.hatchGreen)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#E9E9EE")))

                sectionTitle("SECURITY")
                AuthTextField(label: "Email", placeholder: "you@primahatchery.com", text: $email,
                              icon: "envelope.fill", keyboardType: .emailAddress, textContentType: .username)
                AuthTextField(label: "Password", placeholder: "Minimum 8 characters", text: $password,
                              icon: "lock.fill", isSecure: true, textContentType: .newPassword)
                AuthTextField(label: "Confirm Password", placeholder: "Re-enter password", text: $confirmPassword,
                              icon: "lock.rotation", isSecure: true, textContentType: .newPassword)

                if !confirmPassword.isEmpty && password != confirmPassword {
                    Label("Passwords do not match", systemImage: "xmark.circle.fill")
                        .font(.caption).foregroundColor(.red)
                }

                Toggle(isOn: $acceptedTerms) {
                    HStack(spacing: 4) {
                        Text("I agree to the").foregroundColor(.secondary)
                        Button("Terms of Service") { showTerms = true }
                            .foregroundColor(.hatchGreen)
                    }
                    .font(.footnote)
                }
                .tint(.hatchGreen)

                if let message = localError ?? (session.showAuthError ? session.authErrorMessage : nil) {
                    AuthErrorBanner(message: message)
                }

                AuthPrimaryButton(title: "Create Account", isLoading: session.isLoadingAuth,
                                  isEnabled: isFormValid && !session.isLoadingAuth,
                                  accentColor: .hatchGreenDeep, action: signUp)

                NavigationLink(destination: RoleLoginView(role: role)) {
                    HStack(spacing: 4) {
                        Text("Already have an account?").foregroundColor(.secondary)
                        Text("Sign In").fontWeight(.bold).foregroundColor(.hatchGreen)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AuthScreenBackground())
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showBiometricSetup) {
            BiometricSetupView(role: role)
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack { TermsOfServiceView() }
        }
        .onAppear { session.chooseRole(role) }
        .onDisappear {
            session.showAuthError = false
            session.authErrorMessage = nil
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.caption.weight(.bold)).tracking(1.4).foregroundColor(.hatchOrange)
    }

    private func signUp() {
        localError = nil
        guard password.count >= 8 else { localError = "Password must be at least 8 characters."; return }
        guard password == confirmPassword else { localError = "Passwords do not match."; return }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "termsAcceptedAt")

        session.chooseRole(role)
        session.firebaseSignUp(email: email.trimmingCharacters(in: .whitespaces), password: password,
                               fullName: fullName.trimmingCharacters(in: .whitespaces), siteID: siteID) { success in
            guard success else { return }
            if session.canEnableBiometrics && !session.biometricsEnabled {
                showBiometricSetup = true
            } else {
                session.completeAuthentication(usingFaceID: false)
            }
        }
    }
}

// MARK: - Forgot Password

struct ForgotPasswordView: View {
    @State var prefilledEmail: String
    @State private var isSending = false
    @State private var sent = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AuthBackButton()

                Image(systemName: "lock.rotation")
                    .font(.title)
                    .foregroundColor(.hatchGreen)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(Color.hatchGreenSoft))
                    .frame(maxWidth: .infinity)

                Text(sent ? "Check your email" : "Forgot Password")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity)
                Text(sent
                     ? "We sent a password reset link to \(prefilledEmail). Open it on any device, choose a new password, then sign in."
                     : "Enter your registered email address and we'll send a secure link to reset your HatchPlan password.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                if !sent {
                    AuthTextField(label: "Email address", placeholder: "you@primahatchery.com", text: $prefilledEmail,
                                  icon: "envelope.fill", keyboardType: .emailAddress, textContentType: .username)
                }

                if let errorMessage { AuthErrorBanner(message: errorMessage) }

                AuthPrimaryButton(title: sent ? "Resend Link" : "Send Reset Link", isLoading: isSending,
                                  isEnabled: prefilledEmail.contains("@") && !isSending,
                                  accentColor: .hatchGreenDeep, action: send)

                HStack(spacing: 12) {
                    infoCard(icon: "checkmark.shield.fill", title: "ENCRYPTED", body: "Reset links are single-use and expire automatically.")
                    infoCard(icon: "bolt.fill", title: "INSTANT", body: "Delivered by Firebase Authentication within seconds.")
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(AuthScreenBackground())
        .navigationBarHidden(true)
    }

    private func send() {
        isSending = true
        errorMessage = nil
        FirebaseAuthService.shared.resetPassword(email: prefilledEmail.trimmingCharacters(in: .whitespaces)) { result in
            isSending = false
            switch result {
            case .success: sent = true
            case .failure(let error): errorMessage = error.localizedDescription
            }
        }
    }

    private func infoCard(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundColor(.hatchGreen)
            Text(title).font(.caption.weight(.bold)).tracking(1)
            Text(body).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white))
    }
}
