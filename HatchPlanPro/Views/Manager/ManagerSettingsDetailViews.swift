import SwiftUI
import Combine

struct ManagerAccessibilityView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var highContrastEnabled = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                ManagerDetailHeader(title: "Accessibility")

                sectionLabel("VISION")

                VStack(spacing: 0) {
                    toggleRow(icon: "circle.lefthalf.filled", iconColor: .hatchGreen, title: "High Contrast Mode", isOn: $highContrastEnabled)
                    divider

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            iconBadge(icon: "textformat.size", color: .hatchOrange)
                            Text("Text Size")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        Text("The biological precision of HatchPlan Pro ensures every batch is tracked with surgical accuracy.")
                            .font(.system(size: 16 * session.accessibilityTextScale, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white))

                        HStack(spacing: 10) {
                            Text("T")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.secondary)
                            Slider(value: Binding(get: { session.accessibilityTextScale }, set: { session.setAccessibilityTextScale($0) }), in: 0.85...1.35)
                                .tint(.hatchGreen)
                            Text("T")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("High Contrast Mode increases the contrast between text and background for improved readability.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                }
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: "#F5F6F8")))

                sectionLabel("INTERACTION")

                VStack(spacing: 0) {
                    voiceOverToggleRow
                    Text("VoiceOver speaks items on the screen to help you navigate without seeing them. Toggle opens iOS Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                }
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: "#F5F6F8")))
                .onAppear {
                    session.refreshVoiceOverStatus()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("INDUSTRIAL PRECISION")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundColor(.white.opacity(0.9))
                    Text("Optimized for Every User")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: "#015F78"), Color(hex: "#1F8C9F")], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func toggleRow(icon: String, iconColor: Color, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon: icon, color: iconColor)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.hatchGreen)
                .accessibilityLabel(title)
        }
        .padding(16)
    }

    private var voiceOverToggleRow: some View {
        HStack(spacing: 12) {
            iconBadge(icon: "person.wave.2.fill", color: Color(hex: "#922D60"))
            Toggle(isOn: session.voiceOverToggleBinding) {
                Text("VoiceOver")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .tint(.hatchGreen)
        }
        .padding(16)
        .accessibilityHint("Opens iOS Settings where VoiceOver can be turned on or off")
    }

    private func iconBadge(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(color)
            .frame(width: 34, height: 34)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.opacity(0.12)))
    }

    private var divider: some View {
        Divider().padding(.leading, 62)
    }
}

struct ManagerBiometricSecurityView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ManagerDetailHeader(title: "Security")

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 92, height: 92)
                    .overlay(
                        Image(systemName: session.biometricType.iconName)
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(.hatchGreen)
                    )
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("Biometric Security")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                    Text("Enable FaceID or TouchID to quickly and securely access your hatchery data and approve production plans.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                BiometricSettingsSection()

                VStack(alignment: .leading, spacing: 8) {
                    Text("SECURITY ADVISORY")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundColor(.hatchGreen)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.hatchOrange)
                        Text("HatchPlan Pro uses encrypted system-level authentication. Your biometric data is never stored on our servers or shared with third parties.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#F5F6F8")))

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: "#0F5132"), Color(hex: "#1D7A59")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 140)
                    Text("SECURED ENVIRONMENT")
                        .font(.caption2.weight(.bold))
                        .tracking(1)
                        .foregroundColor(.white)
                        .padding(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

}

struct ManagerChangePasscodeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPasscode = ""
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var showError = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ManagerDetailHeader(title: "Change Passcode")

                Circle()
                    .fill(Color.hatchGreen)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "arrow.2.circlepath")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .padding(.top, 6)

                VStack(spacing: 6) {
                    Text("Change Passcode")
                        .font(.title2.weight(.bold))
                    Text("Ensure your hatchery data remains secure by updating your access code regularly.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }

                passcodeField(title: "CURRENT PASSCODE", icon: "number", text: $currentPasscode)
                passcodeField(title: "NEW PASSCODE", icon: "ellipsis", text: $newPasscode)
                passcodeField(title: "CONFIRM NEW PASSCODE", icon: "checkmark.shield", text: $confirmPasscode)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: showError ? "xmark.octagon.fill" : "info.circle.fill")
                        .foregroundColor(showError ? .red : .hatchOrange)
                    Text(showError ? "Passcodes must match and contain at least 6 characters." : "Your passcode must be at least 6 characters long. Avoid using simple sequences like '123456'.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#F5F6F8")))

                Button(action: confirmPasscodeChange) {
                    Text("Confirm Passcode")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.hatchGreen))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func passcodeField(title: String, icon: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundColor(.hatchOrange)

            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                SecureField("", text: text)
                    .textContentType(.password)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(hex: "#EDEFF2")))
        }
    }

    private func confirmPasscodeChange() {
        showError = !(newPasscode.count >= 6 && newPasscode == confirmPasscode)
        if !showError {
            dismiss()
        }
    }
}

struct ManagerUserManualView: View {
    @State private var query = ""

    private let categories: [(icon: String, title: String, subtitle: String)] = [
        ("sparkles", "Getting Started", "Initial setup and workspace configuration"),
        ("shippingbox.fill", "Batch Management", "Tracking cycles from egg to hatching"),
        ("dot.radiowaves.left.and.right", "Sensor Integration", "Calibrating IoT humidity and temp nodes"),
        ("chart.line.uptrend.xyaxis", "Advanced Analytics", "Predictive modeling and hatch rate ROI"),
        ("wrench.and.screwdriver.fill", "Troubleshooting", "Common error codes and hardware fixes")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                ManagerDetailHeader(title: "User Manual")

                VStack(alignment: .leading, spacing: 4) {
                    Text("DOCUMENTATION PORTAL")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundColor(.hatchOrange)
                    Text("How can we help?")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search manuals, sensors, or batch tips...", text: $query)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#EDEFF2")))

                HStack(spacing: 10) {
                    quickCard(title: "Quick Start\nGuide", subtitle: "Ready to hatch? Set up your first batch in 5 minutes.", icon: "book.fill", color: .hatchGreen)
                    quickCard(title: "Live Support", subtitle: "Connect with an agronomist for critical assistance.", icon: "headphones", color: .hatchOrange)
                }

                Text("MANUAL CATEGORIES")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundColor(.secondary)
                    .padding(.top, 6)

                VStack(spacing: 10) {
                    ForEach(categories, id: \.title) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .foregroundColor(.hatchGreen)
                                .frame(width: 30, height: 30)
                                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.hatchGreenSoft))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.headline)
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#F5F6F8")))
                    }
                }

                Text("EDITOR'S PICK")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundColor(.secondary)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 8) {
                    Text("NEW UPDATE")
                        .font(.caption2.weight(.bold))
                        .tracking(1)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.hatchOrange))
                    Text("Optimizing Humidity for Winter Cycles")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    Text("Learn how to combat seasonal dry air in your facility.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: "#8C5E08"), Color(hex: "#C18A19")], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func quickCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color))
    }
}

struct ManagerTermsView: View {
    @State private var accepted = false

    private let termsBlocks: [(title: String, body: String)] = [
        ("1. Acceptance of Terms", "By creating a HatchPlan Pro account and using our tools, you acknowledge that you have read and accepted these terms."),
        ("2. User Responsibilities", "Users are responsible for maintaining credential security, validating batch data, and keeping sensor calibrations accurate."),
        ("3. Service Availability", "HatchPlan Pro aims for 99.9% uptime. Scheduled maintenance windows may temporarily limit service access."),
        ("4. Data Ownership & Intellectual Property", "All biological data uploaded remains your operational asset. HatchPlan retains platform intellectual property rights."),
        ("5. Limitation of Liability", "To the maximum extent permitted by law, HatchPlan is not liable for indirect losses resulting from outages or miscalibration."),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                ManagerDetailHeader(title: "Terms of Service")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Terms of Service")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.hatchGreen)
                    Text("Welcome to HatchPlan Pro. These terms govern your use of our industrial hatchery management systems.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.hatchGreenSoft))

                VStack(spacing: 10) {
                    ForEach(termsBlocks, id: \.title) { block in
                        Text(block.body)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#F5F6F8")))
                    }
                }

                HStack(spacing: 10) {
                    Button(action: { accepted.toggle() }) {
                        Image(systemName: accepted ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundColor(accepted ? .hatchGreen : .secondary)
                    }
                    .buttonStyle(.plain)

                    Text("I acknowledge that I have read and agree to the Terms of Service")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                Button(action: {}) {
                    Text("I Accept")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(accepted ? Color.hatchGreen : Color.gray))
                }
                .buttonStyle(.plain)
                .disabled(!accepted)

                Text("PRECISION POULTRY SYSTEMS")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct ManagerPrivacyView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                ManagerDetailHeader(title: "Privacy Policy")

                Text("EFFECTIVE OCT 2023")
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.hatchGreenSoft))

                Text("Industrial Data Integrity")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("HatchPlan Pro is engineered for precision agriculture. Your hatchery's operational data is the lifeblood of your business, and we treat its security with mechanical rigor and organic care.")
                    .font(.body)
                    .foregroundColor(.secondary)

                privacyCard(icon: "list.bullet.rectangle.fill", color: .hatchGreen, title: "Data Collection", body: "We collect high-fidelity telemetry from your incubation units, including temperature fluctuation, humidity levels, and hatch metrics.", bullets: ["Facility, hatchery configurations", "Sensor calibration logs", "Batch lifecycle timestamps"])

                privacyCard(icon: "lock.shield.fill", color: Color(hex: "#8A6B11"), title: "Biometric Security", body: "Access to critical facility controls requires mandatory multi-factor authentication.", bullets: ["Encrypted protocols", "Local biometric verification"])

                privacyCard(icon: "square.and.arrow.up.trianglebadge.exclamationmark", color: Color(hex: "#40483F"), title: "Third-Party Sharing", body: "We only share performance data when legally required or when you explicitly authorize integrations.", bullets: ["No resale of operational data", "Anonymized insights only"])

                VStack(alignment: .leading, spacing: 8) {
                    Text("The Digital Agronomist Promise")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("We maintain a zero-trust policy for all digital interactions. Your data is isolated, encrypted at rest using AES-256 standards, and audited quarterly for industrial compliance.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [Color.hatchGreen, Color(hex: "#2D7A35")], startPoint: .topLeading, endPoint: .bottomTrailing))
                )

                Text("END OF DOCUMENT")
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func privacyCard(icon: String,
                             color: Color,
                             title: String,
                             body: String,
                             bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.headline)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color))
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Text(body)
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(bullets, id: \.self) { bullet in
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                    Text(bullet)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#F5F6F8")))
    }
}

struct ManagerAccountDetailsView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                ManagerDetailHeader(title: "Account Details")

                VStack(spacing: 6) {
                    Circle()
                        .fill(LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 110, height: 110)
                        .overlay(Image(systemName: "person.fill").font(.system(size: 44)).foregroundColor(.white))

                    Text("Supervisor Nadunika")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("SENIOR HATCHERY LEAD")
                        .font(.headline.weight(.semibold))
                        .tracking(1.1)
                        .foregroundColor(.hatchGreen.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)

                sectionLabel("FACILITY DETAILS")
                detailsCard {
                    detailsRow(icon: "location", title: "HATCHERY LOCATION", value: "Meegoda Prima", chevron: true)
                    Divider().padding(.leading, 42)
                    detailsRow(icon: "person.badge.key", title: "EMPLOYEE ID", value: "HP-PRO-8842", chevron: false)
                }

                sectionLabel("CONTACT INFORMATION")
                detailsCard {
                    detailsRow(icon: "envelope", title: "EMAIL", value: session.currentUser.email, chevron: true)
                    Divider().padding(.leading, 42)
                    detailsRow(icon: "phone", title: "PHONE NUMBER", value: "+94 77 123 4567", chevron: true)
                }

                Button(action: { session.signOut() }) {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.red.opacity(0.14)))
                }
                .buttonStyle(.plain)
                .padding(.top, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func detailsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#F5F6F8")))
    }

    private func detailsRow(icon: String, title: String, value: String, chevron: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.hatchGreen)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Spacer()

            if chevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
    }
}

struct ManagerContactSupportView: View {
    @State private var searchText = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                ManagerDetailHeader(title: "Contact Support")

                VStack(spacing: 10) {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#123A1F"), Color(hex: "#2B6D34")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 84, height: 84)
                        .overlay(Image(systemName: "person.crop.circle.fill.badge.checkmark").font(.system(size: 36)).foregroundColor(.white))

                    Text("Talk to a Specialist")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    Text("Our industrial poultry experts are online and ready to assist with your hatchery optimization.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.hatchGreen))

                sectionLabel("DIRECT CHANNELS")

                VStack(spacing: 10) {
                    contactRow(icon: "message", color: .hatchGreen, title: "Live Chat", subtitle: "Response time: ~2 mins")
                    contactRow(icon: "at", color: .hatchOrange, title: "Email Support", subtitle: "For detailed technical inquiries")
                    contactRow(icon: "phone.down", color: Color(hex: "#BB3A63"), title: "Request a Call", subtitle: "Available 08:00 - 18:00 GMT")
                }

                Button(action: {}) {
                    Text("Send a Message")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.hatchGreen))
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search Help Center...", text: $searchText)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#EDEFF2")))

                HStack(spacing: 10) {
                    helpTile(icon: "book.closed", title: "User Manuals", subtitle: "Step-by-step guides for hardware setup.")
                    helpTile(icon: "questionmark.square", title: "FAQs", subtitle: "Quick answers to common hatch questions.")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func contactRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.opacity(0.15)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#F5F6F8")))
    }

    private func helpTile(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.hatchGreen)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#F0F1F5")))
    }
}

private struct ManagerDetailHeader: View {
    @Environment(\.dismiss) private var dismiss
    let title: String

    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.hatchGreen)
                    .frame(width: 42, height: 42)
            }
            Spacer()
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.hatchGreen)
            Spacer()
            Color.clear
                .frame(width: 42, height: 42)
        }
        .padding(.horizontal, 4)
    }
}

private func sectionLabel(_ text: String) -> some View {
    HStack {
        Text(text)
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundColor(.secondary)
        Spacer()
    }
}
