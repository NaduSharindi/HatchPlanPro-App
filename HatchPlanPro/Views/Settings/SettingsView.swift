//
//  SettingsView.swift
//  HatchPlanPro
//
//  Settings for both roles: preferences, security, support and account.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage(Haptics.preferenceKey) private var hapticsEnabled = true
    @AppStorage(SpotlightIndexer.preferenceKey) private var spotlightEnabled = true
    @State private var showSignOutConfirm = false
    @State private var notificationsDenied = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ScreenHeader(title: "Settings", showsBack: false) {
                    ProfileAvatar(profile: session.currentUser, size: 36)
                }

                NavigationLink(destination: ProfileView()) {
                    HStack(spacing: 14) {
                        ProfileAvatar(profile: session.currentUser, size: 52)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.currentUser.fullName.isEmpty ? session.currentRole.shortTitle : session.currentUser.fullName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(session.currentRole.shortTitle) • \(session.currentUser.email)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
                }
                .buttonStyle(.plain)

                SettingsSection(title: "PREFERENCES") {
                    SettingsToggleRow(icon: "bell.fill", title: "System Notifications",
                                      subtitle: "Approval and incubation alerts", isOn: $notificationsEnabled)
                    SettingsDivider()
                    SettingsToggleRow(icon: "iphone.radiowaves.left.and.right", title: "Haptic Feedback",
                                      subtitle: "Vibration on scans, approvals and saves", isOn: $hapticsEnabled)
                    SettingsDivider()
                    SettingsToggleRow(icon: "magnifyingglass", title: "Siri & Search",
                                      subtitle: "Find batches from iOS Search", isOn: $spotlightEnabled)
                    SettingsDivider()
                    SettingsLinkRow(icon: "accessibility", title: "Accessibility") { AccessibilitySettingsView() }
                }

                if notificationsDenied {
                    Label {
                        Text("Notifications are turned off for HatchPlan Pro in iOS Settings.")
                    } icon: {
                        Image(systemName: "bell.slash.fill")
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "#9A6B00"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF9E6")))
                    .onTapGesture { session.openSystemSettings() }
                }

                SettingsSection(title: "SECURITY") {
                    SettingsLinkRow(icon: session.biometricType.iconName, title: "Biometric Authentication",
                                    value: session.biometricsEnabled ? "On" : "Off") { BiometricSecurityView() }
                    SettingsDivider()
                    SettingsLinkRow(icon: "key.fill", title: "Change Password") { ChangePasswordView() }
                }

                SettingsSection(title: "SUPPORT") {
                    SettingsLinkRow(icon: "book.fill", title: "User Manual", accent: .hatchOrange) { UserManualView() }
                    SettingsDivider()
                    SettingsLinkRow(icon: "headphones", title: "Contact Support", accent: .hatchOrange) { ContactSupportView() }
                    SettingsDivider()
                    SettingsLinkRow(icon: "doc.text.fill", title: "Terms of Service", accent: .hatchOrange) { TermsOfServiceView() }
                    SettingsDivider()
                    SettingsLinkRow(icon: "hand.raised.fill", title: "Privacy Policy", accent: .hatchOrange) { PrivacyPolicyView() }
                }

                Button(role: .destructive, action: { showSignOutConfirm = true }) {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.red.opacity(0.1)))
                }

                VStack(spacing: 4) {
                    Text("HatchPlan Pro").font(.callout.weight(.medium))
                    Text(appVersion).font(.footnote)
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Sign out of HatchPlan Pro?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { session.signOut() }
        } message: {
            Text("Batches saved offline stay on this device and sync after you sign in again.")
        }
        .onChange(of: notificationsEnabled) { _, enabled in
            guard enabled else { return }
            PushNotificationService.shared.requestAuthorization { granted in
                notificationsDenied = !granted
            }
        }
        .onChange(of: spotlightEnabled) { _, enabled in
            if enabled { SpotlightIndexer.index(session.hatchPlans) } else { SpotlightIndexer.removeAll() }
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsDenied = notificationsEnabled && settings.authorizationStatus == .denied
        }
    }
}

// MARK: - Building Blocks

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            VStack(spacing: 0, content: content)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
        }
    }
}

struct SettingsDivider: View {
    var body: some View { Divider().padding(.leading, 62) }
}

struct SettingsIcon: View {
    let icon: String
    var accent: Color = .hatchGreen

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(accent)
            .frame(width: 34, height: 34)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(accent.opacity(0.13)))
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                SettingsIcon(icon: icon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body)
                    if let subtitle { Text(subtitle).font(.caption).foregroundColor(.secondary) }
                }
            }
        }
        .tint(.hatchGreen)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct SettingsLinkRow<Destination: View>: View {
    let icon: String
    let title: String
    var value: String? = nil
    var accent: Color = .hatchGreen
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                SettingsIcon(icon: icon, accent: accent)
                Text(title).font(.body).foregroundColor(.primary)
                Spacer()
                if let value { Text(value).font(.subheadline).foregroundColor(.secondary) }
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ProfileAvatar: View {
    let profile: HatcheryUserProfile
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let data = profile.photoData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Text(profile.initials.isEmpty ? "?" : profile.initials)
                    .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                    .foregroundColor(.hatchGreen)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.hatchGreenSoft)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("Profile photo of \(profile.fullName)")
    }
}
