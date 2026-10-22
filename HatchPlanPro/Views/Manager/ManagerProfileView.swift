import SwiftUI

struct ManagerSettingsView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var systemNotificationsEnabled = true
    @State private var hapticFeedbackEnabled = true
    @State private var siriSearchEnabled = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                profileCard
                sectionTitle("PREFERENCES")
                settingsCard {
                    toggleRow(icon: "bell.fill", title: "System Notifications", isOn: $systemNotificationsEnabled)
                    divider
                    toggleRow(icon: "iphone.radiowaves.left.and.right", title: "Haptic Feedback", isOn: $hapticFeedbackEnabled)
                    divider
                    toggleRow(icon: "mic.fill", title: "Siri & Search", isOn: $siriSearchEnabled)
                    divider
                    navigationRow(icon: "accessibility", title: "Accessibility") {
                        ManagerAccessibilityView()
                    }
                }

                sectionTitle("SECURITY")
                settingsCard {
                    navigationRow(icon: "faceid", title: "Biometric Authentication") {
                        ManagerBiometricSecurityView()
                    }
                    divider
                    navigationRow(icon: "key.fill", title: "Change Passcode") {
                        ManagerChangePasscodeView()
                    }
                }

                sectionTitle("SUPPORT")
                settingsCard {
                    navigationRow(icon: "book.fill", title: "User Manual", accent: .hatchOrange) {
                        ManagerUserManualView()
                    }
                    divider
                    navigationRow(icon: "headphones", title: "Contact Support", accent: .hatchOrange) {
                        ManagerContactSupportView()
                    }
                    divider
                    navigationRow(icon: "doc.text.fill", title: "Terms of Service", accent: .hatchOrange) {
                        ManagerTermsView()
                    }
                    divider
                    navigationRow(icon: "shield.lefthalf.filled", title: "Privacy Policy", accent: .hatchOrange) {
                        ManagerPrivacyView()
                    }
                }

                VStack(spacing: 4) {
                    Text("HatchPlan Pro")
                        .font(.callout.weight(.medium))
                        .foregroundColor(.secondary)
                    Text("v2.4.0")
                        .font(.footnote)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "arrow.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.hatchGreen)
                    .frame(width: 42, height: 42)
            }

            Spacer()

            Text("Settings")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.hatchGreen)

            Spacer()

            Circle()
                .fill(LinearGradient(colors: [.brown.opacity(0.7), .black.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(Text("M").font(.caption.weight(.bold)).foregroundColor(.white))
                .frame(width: 42, height: 42)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    private var profileCard: some View {
        NavigationLink {
            ManagerAccountDetailsView()
                .environmentObject(session)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.hatchGreen)
                    .frame(width: 56, height: 56)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.hatchGreenSoft))

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.currentRole.shortTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(session.currentUser.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.top, 4)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(0)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            settingsIcon(icon: icon)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.hatchGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func navigationRow<Destination: View>(icon: String,
                                                   title: String,
                                                   accent: Color = .hatchGreen,
                                                   @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                settingsIcon(icon: icon, accent: accent)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func settingsIcon(icon: String, accent: Color = .hatchGreen) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(accent)
            .frame(width: 34, height: 34)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(accent.opacity(0.12)))
    }

    private var divider: some View {
        Divider().padding(.leading, 62)
    }
}

#Preview {
    NavigationStack {
        ManagerSettingsView()
            .environmentObject(AppSessionViewModel())
    }
}
