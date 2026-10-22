//
//  SupervisorAuthFlowViews.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-12.
//

import SwiftUI

struct SupervisorSplashView: View {
    var body: some View {
        SupervisorOnboardingView()
    }
}

struct SupervisorOnboardingView: View {
    @State private var goToLogin = false

    var body: some View {
        ZStack {
            AuthScreenBackground()

            OnboardingFlowView(
                pages: AppOnboardingContent.supervisorPages,
                accentColor: .hatchGreen,
                finishButtonTitle: "Continue to Sign In",
                onSkip: { goToLogin = true },
                onFinish: { goToLogin = true }
            )
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $goToLogin) {
            SupervisorLoginView()
        }
    }
}

struct SupervisorLoginView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showBiometricSetup = false

    private var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    private let biometric = BiometricAuthService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AuthBackButton()

                AuthHeader(
                    title: "Supervisor Sign In",
                    subtitle: "Access your hatchery dashboard, batches, and alerts.",
                    accentColor: .hatchGreen,
                    systemImage: "person.crop.circle.badge.checkmark"
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
                    accentColor: .hatchGreen,
                    action: signInWithEmail
                )
                .padding(.horizontal, 24)

                if BiometricAuthService.shared.isBiometricAvailable {
                    Button(action: signInWithBiometrics) {
                        HStack(spacing: 8) {
                            Image(systemName: biometric.biometricIconName)
                            Text(biometricSignInTitle)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.hatchGreen)
                    }
                    .accessibilityLabel("Sign in with biometrics")
                }

                VStack(spacing: 12) {
                    NavigationLink(destination: SupervisorForgotPasswordView()) {
                        Text("Forgot Password?")
                            .foregroundColor(.secondary)
                    }
                    NavigationLink(destination: SupervisorSignUpView()) {
                        Text("Don't have an account? Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.hatchGreen)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 32)
        }
        .background(AuthScreenBackground())
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showBiometricSetup) {
            BiometricSetupView(role: .supervisor)
        }
        .onAppear {
            if session.canUseBiometricSignIn {
                session.restoreStoredSession()
            }
        }
        .onDisappear {
            session.showAuthError = false
            session.authErrorMessage = nil
        }
    }

    private var biometricSignInTitle: String {
        if session.canUseBiometricSignIn {
            return "Unlock with \(biometric.biometricName)"
        }
        return "Sign In with \(biometric.biometricName)"
    }

    private func signInWithEmail() {
        session.chooseRole(.supervisor)
        session.firebaseSignIn(email: email.trimmingCharacters(in: .whitespaces), password: password) { success in
            if success {
                if session.shouldOfferBiometricEnrollment {
                    showBiometricSetup = true
                } else {
                    session.completeAuthentication(usingFaceID: false)
                }
            }
        }
    }

    private func signInWithBiometrics() {
        session.chooseRole(.supervisor)

        if session.canUseBiometricSignIn {
            session.attemptBiometricUnlock { success, error in
                if !success, let error {
                    session.authErrorMessage = biometric.localizedErrorMessage(from: error)
                    session.showAuthError = true
                }
            }
            return
        }

        guard biometric.isEnabled else {
            session.authErrorMessage = "Sign in with email and password once, then enable \(biometric.biometricName)."
            session.showAuthError = true
            return
        }

        session.authErrorMessage = "Sign in with your email and password to restore your session first."
        session.showAuthError = true
    }
}


// MARK: - Supervisor Sign Up
struct SupervisorSignUpView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var localError: String?
    @State private var showBiometricSetup = false
    @Environment(\.dismiss) var dismiss

    private let biometric = BiometricAuthService.shared

    private var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty &&
        password.count >= 6 && password == confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 10) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.hatchGreen)
                        .padding(18)
                        .background(Circle().fill(Color.hatchGreenSoft))
                        .accessibilityHidden(true)

                    Text("Create Account")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.hatchGreen)
                        .accessibilityAddTraits(.isHeader)
                    Text("Supervisor registration")
                        .font(.caption.weight(.semibold))
                        .kerning(2.2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 18)

                VStack(alignment: .leading, spacing: 10) {
                    Text("FULL NAME").font(.caption.weight(.bold)).kerning(1.2).foregroundColor(.primary)
                    TextField("Nadunika Sharindi", text: $fullName)
                        .textContentType(.name)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: "#E9E9EE")))
                        .accessibilityLabel("Full name")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("EMAIL ADDRESS").font(.caption.weight(.bold)).kerning(1.2).foregroundColor(.primary)
                    TextField("nadunika@primahatchery.com", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: "#E9E9EE")))
                        .accessibilityLabel("Email address")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("PASSWORD").font(.caption.weight(.bold)).kerning(1.2).foregroundColor(.primary)
                    SecureField("Min. 6 characters", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: "#E9E9EE")))
                        .accessibilityLabel("Password")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("CONFIRM PASSWORD").font(.caption.weight(.bold)).kerning(1.2).foregroundColor(.primary)
                    SecureField("Re-enter password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: "#E9E9EE")))
                        .accessibilityLabel("Confirm password")
                }

                // Error display
                if let errorMsg = localError ?? (session.showAuthError ? session.authErrorMessage : nil) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                        Text(errorMsg).font(.caption).foregroundColor(.red).lineLimit(3)
                    }
                    .accessibilityElement(children: .combine)
                }

                Button {
                    localError = nil
                    guard !fullName.isEmpty else { localError = "Please enter your full name."; return }
                    guard !email.isEmpty else { localError = "Please enter your email."; return }
                    guard password.count >= 6 else { localError = "Password must be at least 6 characters."; return }
                    guard password == confirmPassword else { localError = "Passwords do not match."; return }

                    session.chooseRole(.supervisor)
                    session.firebaseSignUp(email: email, password: password, fullName: fullName) { success in
                        if success {
                            if session.canEnableBiometrics && !session.biometricsEnabled {
                                showBiometricSetup = true
                            } else {
                                session.completeAuthentication(usingFaceID: false)
                            }
                        }
                    }
                } label: {
                    HStack {
                        if session.isLoadingAuth {
                            ProgressView().tint(.white)
                        }
                        Text("Create Account")
                            .font(.headline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.hatchGreen))
                }
                .disabled(!isFormValid || session.isLoadingAuth)
                .opacity(isFormValid ? 1.0 : 0.6)
                .accessibilityLabel("Create account")

                NavigationLink(destination: SupervisorLoginView()) {
                    HStack(spacing: 4) {
                        Text("Already have an account?").foregroundColor(.secondary)
                        Text("Sign In").fontWeight(.semibold).foregroundColor(.hatchGreen)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showBiometricSetup) {
            BiometricSetupView(role: .supervisor)
        }
        .onDisappear {
            session.showAuthError = false
            session.authErrorMessage = nil
        }
    }
}

struct SupervisorBiometricIntroView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    private let biometric = BiometricAuthService.shared

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: biometric.biometricIconName)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.hatchGreen)
                    .padding(28)
                    .background(Circle().fill(Color.white))
                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)

                Text("Enable \(biometric.biometricName)")
                    .font(.title2.bold())
                    .foregroundColor(.black)
                Text("Secure access via \(biometric.biometricName) to your hatchery analytics and biological windows.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 28)
            }
            .supervisorCard()
            .padding(.horizontal, 18)

            Button {
                enableBiometrics()
            } label: {
                Label("Enable \(biometric.biometricName)", systemImage: biometric.biometricIconName)
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.hatchGreen))
            }
            .padding(.horizontal, 24)
            .disabled(!session.canEnableBiometrics || session.isUpdatingBiometrics)
            .opacity(session.canEnableBiometrics ? 1 : 0.5)

            Button {
                session.setBiometricEnabled(false)
                session.completeAuthentication(usingFaceID: false)
            } label: {
                Text("Skip for now")
                    .fontWeight(.semibold)
                    .foregroundColor(.hatchGreen)
            }

            if let message = session.biometricErrorMessage {
                BiometricNoticeBanner(message: message,
                                      showsSettingsAction: biometric.shouldOfferSystemSettings) {
                    session.openSystemSettings()
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func enableBiometrics() {
        session.setBiometricEnabled(true) { success in
            if success {
                session.completeAuthentication(usingFaceID: true, biometricAlreadyVerified: true)
            }
        }
    }
}

struct SupervisorForgotPasswordView: View {
    @State private var email = ""
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "lock.rotation")
                    .font(.title2)
                    .padding(18)
                    .background(Circle().fill(Color.hatchGreenSoft))
                    .foregroundColor(.hatchGreen)
                Spacer()
            }

            Text("Forgot Password")
                .font(.largeTitle.bold())
                .foregroundColor(.hatchGreen)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Enter your registered email address to receive a password reset link for your HatchPlan account.")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                Text("EMAIL ADDRESS").font(.caption.weight(.bold)).kerning(1.2)
                TextField("nadunika@primahatchery.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: "#E9E9EE")))
                    .accessibilityLabel("Email address")
            }
            .supervisorCard()

            if showSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.hatchGreen)
                    Text("Password reset email sent! Check your inbox.")
                        .font(.caption).foregroundColor(.hatchGreen)
                }
            }

            if let errorMsg = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                    Text(errorMsg).font(.caption).foregroundColor(.red).lineLimit(3)
                }
            }

            Button {
                guard !email.isEmpty else {
                    errorMessage = "Please enter your email address."
                    return
                }
                isSending = true
                errorMessage = nil
                showSuccess = false
                FirebaseAuthService.shared.resetPassword(email: email) { result in
                    isSending = false
                    switch result {
                    case .success:
                        showSuccess = true
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                HStack {
                    if isSending { ProgressView().tint(.white) }
                    Text("Send Reset Link")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.hatchGreen))
            }
            .disabled(email.isEmpty || isSending)
            .opacity(email.isEmpty ? 0.6 : 1.0)

            NavigationLink(destination: SupervisorLoginView()) {
                Text("Back to Sign In")
                    .fontWeight(.semibold)
                    .foregroundColor(.hatchGreen)
            }

            HStack {
                infoMiniCard(title: "ENCRYPTED", body: "Bank-grade security protocols for all reset requests.", icon: "shield.fill")
                infoMiniCard(title: "INSTANT", body: "Password reset link delivered via Firebase Auth.", icon: "bolt.fill")
            }

            Spacer()
        }
        .padding(24)
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoMiniCard(title: String, body: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.hatchGreen)
            Text(title).font(.caption.weight(.bold)).kerning(1)
            Text(body).font(.footnote).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
    }
}

struct SupervisorVerificationCodeView: View {
    @State private var code = Array(repeating: "0", count: 6)

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "lock.fill")
                .font(.title)
                .foregroundColor(.hatchGreen)
                .padding(20)
                .background(Circle().fill(Color.hatchGreenSoft))

            Text("Check your email")
                .font(.title.bold())
            Text("Enter the 6-digit code sent to your email")
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                ForEach(code.indices, id: \.self) { index in
                    TextField("0", text: Binding(
                        get: { code[index] },
                        set: { code[index] = $0.prefix(1).description }
                    ))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2.weight(.bold))
                    .frame(width: 48, height: 64)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#E9E9EE")))
                }
            }

            NavigationLink(destination: SupervisorResetPasswordView()) {
                Text("Verify & Continue")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.hatchGreen))
            }

            Button("RESEND CODE") { }
                .fontWeight(.bold)
                .foregroundColor(.hatchGreen)

            Spacer()

            NavigationLink(destination: SupervisorHelpCardView()) {
                HStack {
                    Image(systemName: "headphones")
                        .foregroundColor(.hatchGreen)
                    VStack(alignment: .leading) {
                        Text("Need help?").font(.headline)
                        Text("Contact our agronomist support team").font(.footnote).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .supervisorCard()
            }
        }
        .padding(24)
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationTitle("Verification Code")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupervisorResetPasswordView: View {
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("New Password")
                    .font(.largeTitle.bold())
                Text("Secure your account by choosing a high-strength password for your hatchery operations.")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    passwordField(title: "NEW PASSWORD", text: $password)
                    passwordField(title: "CONFIRM NEW PASSWORD", text: $confirmPassword)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("REQUIREMENTS").font(.caption.weight(.bold)).kerning(1.2)
                        requirementRow(text: "Minimum 8 characters", met: true)
                        requirementRow(text: "Include numbers and symbols", met: true)
                        requirementRow(text: "Passwords must match", met: false)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
                }

                NavigationLink(destination: SupervisorPasswordSuccessView()) {
                    Text("Reset Password")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.hatchGreen))
                }
            }
            .padding(24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func passwordField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.bold)).kerning(1.2).foregroundColor(.hatchGreen)
            SecureField("••••••••", text: text)
                .padding()
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: "#E9E9EE")))
        }
    }

    private func requirementRow(text: String, met: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .hatchGreen : .secondary)
            Text(text).foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct SupervisorPasswordSuccessView: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 62, weight: .bold))
                .foregroundColor(.hatchGreen)
                .padding(28)
                .background(Circle().fill(Color.hatchGreenSoft))

            Text("Password Reset Successful")
                .font(.title.bold())
            Text("Your password has been updated. You can now use your new password to sign in to your account.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            NavigationLink(destination: SupervisorLoginView()) {
                Text("Sign In")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.hatchGreen))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding()
        .background(Color.hatchSurface.ignoresSafeArea())
    }
}

struct SupervisorFaceIDSetupView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    private let biometric = BiometricAuthService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: biometric.biometricIconName)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.hatchGreen)
                    .padding(24)
                    .background(Circle().fill(Color.white))
                    .shadow(color: .black.opacity(0.07), radius: 16, x: 0, y: 8)

                Text("\(biometric.biometricName) Ready")
                    .font(.largeTitle.bold())
                Text("You can now use \(biometric.biometricName) to securely sign in and approve plans in HatchPlan Pro.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Secure protocol", systemImage: "shield.fill")
                        .font(.caption.weight(.bold)).kerning(1.2)
                    Text("Your biometric data is encrypted and never leaves your device.")
                        .foregroundColor(.secondary)
                }
                .supervisorCard()

                if let message = session.biometricErrorMessage {
                    BiometricNoticeBanner(message: message,
                                          showsSettingsAction: biometric.shouldOfferSystemSettings) {
                        session.openSystemSettings()
                    }
                }

                Button {
                    session.setBiometricEnabled(true) { success in
                        if success {
                            session.completeAuthentication(usingFaceID: true, biometricAlreadyVerified: true)
                        }
                    }
                } label: {
                    Text("Enable \(biometric.biometricName)")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.hatchGreen))
                }
                .disabled(!session.canEnableBiometrics || session.isUpdatingBiometrics)
                .opacity(session.canEnableBiometrics ? 1 : 0.5)

                Button {
                    session.setBiometricEnabled(false)
                    session.completeAuthentication(usingFaceID: false)
                } label: {
                    Text("Skip for now")
                        .fontWeight(.semibold)
                        .foregroundColor(.hatchGreen)
                }
            }
            .padding(24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationTitle("\(biometric.biometricName) Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupervisorTouchIDScanView: View {
    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 280, height: 280)
                    .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
                Image(systemName: "touchid")
                    .font(.system(size: 88, weight: .semibold))
                    .foregroundColor(.hatchGreen)
            }
            Text("Scanning Face...")
                .font(.title2.bold())
            Text("Move your head slowly in a circle to show all angles of your face.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            ProgressView(value: 0.75)
                .tint(.hatchGreen)
                .padding(.horizontal, 48)

            HStack {
                smallStatCard(title: "Depth sensor", value: "Optimized")
                smallStatCard(title: "Lighting", value: "Ambient")
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationTitle("FaceID Setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func smallStatCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.caption2.weight(.bold)).kerning(1.1).foregroundColor(.hatchGreen)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
    }
}

struct SupervisorTouchIDReadyView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(.hatchGreen)
            Text("TouchID Ready")
                .font(.largeTitle.bold())
            Text("You can now use your fingerprint to securely sign in and approve plans in HatchPlan Pro.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
            Button {
                session.setBiometricEnabled(true) { _ in
                    session.completeAuthentication(usingFaceID: session.biometricsEnabled,
                                                   biometricAlreadyVerified: true)
                }
            } label: {
                Text("Done")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.hatchGreen))
                    .padding(.horizontal, 24)
            }
            Spacer()
        }
        .background(Color.hatchSurface.ignoresSafeArea())
    }
}

struct SupervisorProfilePhotoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 92, weight: .regular))
                    .foregroundColor(.hatchGreen)
                    .padding(18)
                    .background(Circle().fill(Color.white))
                    .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 8)

                Text("Profile Photo")
                    .font(.title.bold())
                Text("Add a clear profile photo for identity verification and security checks.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 14) {
                    Label("Job Title", systemImage: "briefcase.fill")
                        .foregroundColor(.hatchGreen)
                    Text("Senior Hatchery Lead")
                        .font(.title3)
                    Divider()
                    Label("Employee ID", systemImage: "person.text.rectangle")
                        .foregroundColor(.hatchGreen)
                    Text("HP-99234-X")
                        .font(.title3)
                }
                .supervisorCard()

                VStack(alignment: .leading, spacing: 14) {
                    Label("Hatchery Location", systemImage: "mappin.and.ellipse")
                        .foregroundColor(.hatchGreen)
                    Text("Meegoda Prim").font(.title3)
                }
                .supervisorCard()

                VStack(alignment: .leading, spacing: 14) {
                    Label("Email Address", systemImage: "envelope.fill")
                        .foregroundColor(.hatchGreen)
                    Text("nadunika@primahatchery.com").font(.title3)
                    Divider()
                    Label("Phone Number", systemImage: "phone.fill")
                        .foregroundColor(.hatchGreen)
                    Text("+94 00 000 00 00").font(.title3)
                }
                .supervisorCard()
            }
            .padding(24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationTitle("Profile Photo")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupervisorHelpCardView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.hatchGreen)
            Text("Support team ready")
                .font(.title.bold())
            Text("Contact your hatchery support team if the verification code did not arrive.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
        .padding()
        .background(Color.hatchSurface.ignoresSafeArea())
    }
}
