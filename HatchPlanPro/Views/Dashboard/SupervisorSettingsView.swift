import SwiftUI
import Combine

struct SupervisorSettingsView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel = SupervisorSettingsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Header
                    HStack {
                        Text("Settings")
                            .font(.title2.bold())
                            .foregroundColor(.hatchGreen)
                        Spacer()
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.hatchGreen)
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Profile Section
                    NavigationLink(destination: SupervisorProfileView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.title3)
                                .foregroundColor(.hatchGreen)
                                .padding(10)
                                .background(Circle().fill(Color.hatchGreenSoft))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.roleTitle)
                                    .font(.headline)
                                    .foregroundColor(.hatchGreen)
                                Text(viewModel.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .supervisorCard()
                    .padding(.horizontal, 16)

                    // MARK: - Preferences Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PREFERENCES")
                            .font(.caption.weight(.bold))
                            .kerning(1)

                        settingRow(icon: "bell.fill", title: "System Notifications", enabled: $viewModel.notificationsEnabled)
                        settingRow(icon: "iphone.gen1.radiowaves.left.and.right", title: "Haptic Feedback", enabled: $viewModel.hapticEnabled)
                        settingRow(icon: "mic.fill", title: "Siri & Search", enabled: $viewModel.siriEnabled)
                        
                        NavigationLink(destination: SupervisorAccessibilityView()) {
                            settingRowStatic(icon: "accessibility", title: "Accessibility")
                        }
                    }
                    .supervisorCard()
                    .padding(.horizontal, 16)

                    // MARK: - Security Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SECURITY")
                            .font(.caption.weight(.bold))
                            .kerning(1)

                        NavigationLink(destination: SupervisorBiometricSettingsView()) {
                            settingRowStatic(icon: "faceid", title: "Biometric Authentication")
                        }
                        NavigationLink(destination: SupervisorChangePasscodeView()) {
                            settingRowStatic(icon: "lock.fill", title: "Change Passcode")
                        }
                    }
                    .supervisorCard()
                    .padding(.horizontal, 16)

                    // MARK: - Support Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SUPPORT")
                            .font(.caption.weight(.bold))
                            .kerning(1)

                        NavigationLink(destination: SupervisorUserManualView()) {
                            supportRow(icon: "book.fill", title: "User Manual")
                        }
                        NavigationLink(destination: SupervisorContactSupportView()) {
                            supportRow(icon: "headphones", title: "Contact Support")
                        }
                    }
                    .supervisorCard()
                    .padding(.horizontal, 16)
                    
                    // MARK: - Logout
                    Button(action: { session.signOut() }) {
                        Text("Sign Out")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.red.opacity(0.1)))
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Footer
                    VStack(spacing: 4) {
                        Text("HatchPlan Pro")
                            .font(.caption.weight(.semibold))
                        Text("v2.4.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadData(from: session)
            }
        }
    }

    private func settingRow(icon: String, title: String, enabled: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.hatchGreen)
                .padding(8)
                .background(Circle().fill(Color.hatchGreenSoft))

            Text(title)
                .font(.body)
                .foregroundColor(.hatchGreen)

            Spacer()

            Toggle("", isOn: enabled)
                .labelsHidden()
                .tint(.hatchGreen)
                .accessibilityLabel(title)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FAFAFA")))
    }

    private func settingRowStatic(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.hatchGreen)
                .padding(8)
                .background(Circle().fill(Color.hatchGreenSoft))

            Text(title)
                .font(.body)
                .foregroundColor(.hatchGreen)

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FAFAFA")))
    }

    private func supportRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "#B78900"))
                .padding(8)
                .background(Circle().fill(Color.hatchOrangeSoft))

            Text(title)
                .font(.body)
                .foregroundColor(.hatchGreen)

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FAFAFA")))
    }
}

// MARK: - Accessibility Settings
struct SupervisorAccessibilityView: View {
    @State private var highContrastEnabled = false
    @EnvironmentObject private var session: AppSessionViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Vision Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("VISION")
                            .font(.caption.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.hatchGreen)
                                    .padding(8)
                                    .background(Circle().fill(Color.hatchGreenSoft))

                                Toggle(isOn: $highContrastEnabled) {
                                    Text("High Contrast Mode")
                                        .font(.body)
                                        .foregroundColor(.hatchGreen)
                                }
                                .tint(.hatchGreen)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FAFAFA")))

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Text Size")
                                        .font(.body)
                                        .foregroundColor(.hatchGreen)
                                    Spacer()
                                }
                                HStack(spacing: 12) {
                                    Text("T")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Slider(value: Binding(get: { session.accessibilityTextScale }, set: { session.setAccessibilityTextScale($0) }), in: 0.85...1.45)
                                        .tint(.hatchGreen)
                                        .accessibilityLabel("Text Size")
                                        .accessibilityValue("\(Int(session.accessibilityTextScale * 100)) percent")
                                    Text("T")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FAFAFA")))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("The biological precision of HatchPlan Pro ensures every batch is tracked with surgical accuracy.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#F5F5F5")))
                        }
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Interaction Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("INTERACTION")
                            .font(.caption.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.secondary)

                        Toggle(isOn: session.voiceOverToggleBinding) {
                            Label("VoiceOver", systemImage: "mic.fill")
                                .font(.body)
                                .foregroundColor(.hatchGreen)
                        }
                        .tint(.hatchGreen)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FAFAFA")))
                        .accessibilityHint("Opens iOS Settings where VoiceOver can be turned on or off")

                        Text("VoiceOver speaks items on the screen to help you navigate without seeing them. Toggle opens iOS Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .onAppear {
                        session.refreshVoiceOverStatus()
                    }

                    // MARK: - Feature Card
                    VStack(spacing: 12) {
                        Text("INDUSTRIAL PRECISION")
                            .font(.caption.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.white)

                        Text("Optimized for Every User")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(LinearGradient(colors: [Color.hatchGreen, Color.hatchGreen.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.vertical, 20)
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("Accessibility")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}

// MARK: - Biometric Settings
struct SupervisorBiometricSettingsView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Biometric Icon
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(Color.hatchGreenSoft).frame(width: 100, height: 100)
                            Image(systemName: session.biometricType.iconName)
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundColor(.hatchGreen)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    VStack(spacing: 12) {
                        Text("Biometric Security")
                            .font(.title2.bold())
                            .foregroundColor(.hatchGreen)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text("Enable FaceID or TouchID to quickly and securely access your hatchery data and approve production plans.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Toggle Options
                    BiometricSettingsSection()
                        .padding(.horizontal, 16)

                    // MARK: - Security Advisory
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.hatchGreen)
                            Text("SECURITY ADVISORY")
                                .font(.caption.weight(.bold))
                                .kerning(0.8)
                        }
                        Text("HatchPlan Pro uses secured system-level authentication. Your biometric data is never stored on our servers or shared with third parties.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.hatchGreenSoft.opacity(0.5)))
                    .padding(.horizontal, 16)

                    // MARK: - Feature Image
                    VStack {
                        Text("SECURED ENVIRONMENT")
                            .font(.caption.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(LinearGradient(colors: [Color.hatchGreen, Color.hatchGreen.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.vertical, 20)
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}

// MARK: - Change Passcode
struct SupervisorChangePasscodeView: View {
    @State private var currentPasscode = ""
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 24) {
                    // MARK: - Header Icon
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.hatchGreenSoft).frame(width: 80, height: 80)
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.hatchGreen)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text("Change Passcode")
                            .font(.title2.bold())
                            .foregroundColor(.hatchGreen)

                        Text("Ensure your hatchery data remains secure by updating your access code regularly.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Passcode Fields
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CURRENT PASSCODE")
                                .font(.caption.weight(.bold))
                                .kerning(0.8)
                                .foregroundColor(.secondary)
                            SecureField("Enter current passcode", text: $currentPasscode)
                                .font(.body)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(hex: "#F0F0F0")))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("NEW PASSCODE")
                                .font(.caption.weight(.bold))
                                .kerning(0.8)
                                .foregroundColor(.secondary)
                            SecureField("Enter new passcode", text: $newPasscode)
                                .font(.body)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(hex: "#F0F0F0")))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("CONFIRM NEW PASSCODE")
                                .font(.caption.weight(.bold))
                                .kerning(0.8)
                                .foregroundColor(.secondary)
                            SecureField("Confirm new passcode", text: $confirmPasscode)
                                .font(.body)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(hex: "#F0F0F0")))
                        }

                        if showError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.red.opacity(0.1)))
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.secondary)
                                Text("Your passcode must be at least 6 characters long. Avoid using simple sequences like '123456'")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(hex: "#F5F5F5")))
                        }
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Confirm Button
                    Button(action: validateAndUpdatePasscode) {
                        Text("Confirm Passcode")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.hatchGreen))
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.vertical, 20)
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("Change Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }

    private func validateAndUpdatePasscode() {
        if newPasscode.count < 6 {
            showError = true
            errorMessage = "Passcode must be at least 6 characters"
        } else if newPasscode != confirmPasscode {
            showError = true
            errorMessage = "Passcodes do not match"
        } else if newPasscode.contains("123456") || newPasscode.contains("654321") {
            showError = true
            errorMessage = "Avoid using simple sequences"
        } else {
            showError = false
            dismiss()
        }
    }
}

// MARK: - User Manual
struct SupervisorUserManualView: View {
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss

    let categories = [
        (icon: "paperplane.fill", title: "Getting Started", subtitle: "Initial setup and workspace configuration"),
        (icon: "leaf.fill", title: "Batch Management", subtitle: "Tracking cycles from egg to hatching"),
        (icon: "wifi.router.fill", title: "Sensor Integration", subtitle: "Calibrating IoT humidity and temp modes"),
        (icon: "chart.bar.fill", title: "Advanced Analytics", subtitle: "Predictive yield and health insights"),
        (icon: "wrench.and.screwdriver.fill", title: "Troubleshooting", subtitle: "Common error codes and hardware fixes")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search manuals, sensors, or batch tips...", text: $searchText)
                            .font(.body)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#F0F0F0")))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // MARK: - Quick Links
                    HStack(spacing: 12) {
                        VStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text("Quick Start\nGuide")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.hatchGreen))

                        VStack(spacing: 8) {
                            Image(systemName: "headphones")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text("Live\nSupport")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FFD700")))
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MANUAL CATEGORIES")
                            .font(.caption.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)

                        ForEach(categories, id: \.title) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.icon)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Circle().fill(Color.hatchGreen))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.hatchGreen)
                                    Text(item.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#FAFAFA")))
                            .padding(.horizontal, 16)
                        }
                    }

                    // MARK: - Editor's Pick
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EDITOR'S PICK")
                            .font(.caption.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("NEW UPDATE")
                                    .font(.caption2.weight(.bold))
                                    .kerning(0.8)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color(hex: "#FFD700")))
                                Text("Optimizing Humidity for Winter Cycles")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            Text("Advanced techniques to boost hatch rates in cold seasonal conditions. Ideal for year-round operations.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(LinearGradient(colors: [Color.hatchGreen.opacity(0.8), Color.hatchGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("User Manual")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}

// MARK: - Contact Support
struct SupervisorContactSupportView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    // MARK: - Specialist Card
                    VStack(spacing: 16) {
                        ZStack(alignment: .center) {
                            Circle().fill(Color.hatchGreen).frame(width: 80, height: 80)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        Text("Talk to a Specialist")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Text("Our industrial poultry experts are online and ready to assist with your hatchery optimization.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(LinearGradient(colors: [Color.hatchGreen, Color.hatchGreen.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    // MARK: - Direct Channels
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DIRECT CHANNELS")
                            .font(.caption.weight(.bold))
                            .kerning(1)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "message.fill")
                                    .font(.title2)
                                    .foregroundColor(.hatchGreen)
                                    .padding(10)
                                    .background(Circle().fill(Color.hatchGreenSoft))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Live Chat")
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.hatchGreen)
                                    Text("Response time ~2 mins")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#FAFAFA")))

                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "#B78900"))
                                    .padding(10)
                                    .background(Circle().fill(Color.hatchOrangeSoft))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Email Support")
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.hatchGreen)
                                    Text("For detailed technical inquiries")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#FAFAFA")))

                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "#C83E6C"))
                                    .padding(10)
                                    .background(Circle().fill(Color(hex: "#E8C5D8")))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Request a Call")
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.hatchGreen)
                                    Text("Available 09:00 - 18:00 GMT")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#FAFAFA")))
                        }
                        .padding(.horizontal, 16)
                    }

                    // MARK: - Send Message Button
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                            Text("Send a Message")
                        }
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.hatchGreen))
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.vertical, 20)
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}

// MARK: - Terms of Service
struct SupervisorTermsView: View {
    @State private var termsAccepted = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Header
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.hatchGreen)
                        Text("Terms of Service")
                            .font(.headline)
                            .foregroundColor(.hatchGreen)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.hatchGreenSoft))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 14) {
                        // MARK: - Acceptance of Terms
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.square.fill")
                                    .foregroundColor(.hatchGreen)
                                Text("Acceptance of Terms")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }
                            Text("By accessing and using HatchPlan Pro, you accept and agree to be bound by the terms and provision of this agreement.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        // MARK: - User Responsibilities
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.hatchGreen)
                                Text("User Responsibilities")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }
                            Text("You are responsible for maintaining the confidentiality of your credentials, you understand that you are solely responsible for all activities that occur under your account.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        // MARK: - Service Availability
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "wifi.router.fill")
                                    .foregroundColor(.hatchGreen)
                                Text("Service Availability")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }
                            Text("We strive for system uptime, while we make every effort to maintain the service, we cannot guarantee availability. Scheduled maintenance is performed quarterly during service windows.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        // MARK: - Data Ownership
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.hatchGreen)
                                Text("Data Ownership & Intellectual Property")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }
                            Text("All data generated through the use of HatchPlan Pro remains your property. However, we retain the right to use anonymized data for system improvement and analytics purposes only.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        // MARK: - Limitation of Liability
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.hatchGreen)
                                Text("Limitation of Liability")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }
                            Text("HatchPlan Pro and its operators shall not be liable for any indirect, incidental, special, consequential or punitive damages resulting from your use of or inability to use the services.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#FAFAFA")))
                    .padding(.horizontal, 16)

                    // MARK: - Acceptance Checkbox
                    HStack(spacing: 12) {
                        Button(action: { termsAccepted.toggle() }) {
                            Image(systemName: termsAccepted ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundColor(termsAccepted ? .hatchGreen : .secondary)
                        }
                        Text("I acknowledge that I have read and agree to the Terms of Service")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(hex: "#F5F5F5")))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(.vertical, 20)
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}

// MARK: - Privacy Policy
struct SupervisorPrivacyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Header
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .font(.title2)
                            .foregroundColor(.hatchGreen)
                        Text("Privacy Policy")
                            .font(.headline)
                            .foregroundColor(.hatchGreen)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.hatchGreenSoft))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.hatchGreen)
                                Text("Introduction")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }
                            Text("HatchPlan Pro is committed to protecting your privacy. This policy outlines how we collect, use, and safeguard your information when you use our application.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "cylinder.split.1x2.fill")
                                    .foregroundColor(.hatchGreen)
                                Text("Information Collection")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }
                            Text("We collect information you provide directly (profile data, batch information) and usage data to improve our services. All data transmission is encrypted using industry-standard security protocols.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.hatchGreen)
                                Text("Data Security")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }
                            Text("Your data is protected by multi-layer encryption and access controls. We conduct regular security audits and comply with international data protection regulations (GDPR, CCPA).")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.hatchGreen)
                                Text("Third-Party Sharing")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }
                            Text("We do not sell or share your personal data with third parties without explicit consent. Only anonymized, aggregated data may be used for industry analytics and service improvement.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.hatchGreen)
                                Text("Your Rights")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.hatchGreen)
                            }
                            Text("You have the right to access, modify, or delete your personal data at any time. Contact support to exercise these rights or for any privacy-related questions.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#FAFAFA")))
                    .padding(.horizontal, 16)

                    // MARK: - Last Updated
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LAST UPDATED")
                            .font(.caption.weight(.bold))
                            .kerning(0.8)
                            .foregroundColor(.secondary)
                        Text("May 14, 2026")
                            .font(.body)
                            .foregroundColor(.hatchGreen)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(hex: "#F5F5F5")))
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.vertical, 20)
            }
            .background(Color.hatchSurface.ignoresSafeArea())
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}
