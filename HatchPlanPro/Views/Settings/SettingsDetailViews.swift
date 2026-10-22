//
//  SettingsDetailViews.swift
//  HatchPlanPro
//
//  Accessibility, security, password, manual, support and legal screens.
//

import SwiftUI

/// Placeholder support contacts for the deployment. Replace with the
/// hatchery's real support desk before release.
enum SupportContact {
    static let email = "support@hatchplanpro.example"
    static let phone = "+94110000000"
    static let displayPhone = "+94 11 000 0000"
    static let hours = "Mon–Sat, 08:00–18:00 (Sri Lanka time)"
}

private struct DetailScaffold<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(title: title)
                content()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Accessibility

struct AccessibilitySettingsView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @AppStorage("highContrastEnabled") private var highContrast = false

    var body: some View {
        DetailScaffold(title: "Accessibility") {
            SettingsSection(title: "VISION") {
                SettingsToggleRow(icon: "circle.lefthalf.filled", title: "High Contrast Mode",
                                  subtitle: "Bolder text throughout the app", isOn: $highContrast)
                SettingsDivider()
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        SettingsIcon(icon: "textformat.size", accent: .hatchOrange)
                        Text("Text Size").font(.body)
                    }
                    Text("The biological precision of HatchPlan Pro ensures every batch is tracked with surgical accuracy.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchSurface))
                    HStack(spacing: 10) {
                        Image(systemName: "textformat.size.smaller").foregroundColor(.secondary)
                        Slider(value: Binding(get: { session.accessibilityTextScale },
                                              set: { session.setAccessibilityTextScale($0) }),
                               in: 0.85...1.45)
                            .tint(.hatchGreen)
                            .accessibilityLabel("Text size")
                        Image(systemName: "textformat.size.larger").foregroundColor(.secondary)
                    }
                    Text(session.isVoiceOverRunning
                         ? "VoiceOver is on, so text follows your iOS Dynamic Type setting."
                         : "Applies across HatchPlan Pro. iOS Dynamic Type is respected when VoiceOver is on.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(14)
            }

            SettingsSection(title: "INTERACTION") {
                Toggle(isOn: session.voiceOverToggleBinding) {
                    HStack(spacing: 12) {
                        SettingsIcon(icon: "person.wave.2.fill", accent: Color(hex: "#922D60"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("VoiceOver")
                            Text("Opens iOS Settings › Accessibility").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .tint(.hatchGreen)
                .padding(14)
            }
        }
        .onAppear { session.refreshVoiceOverStatus() }
    }
}

// MARK: - Biometrics

struct BiometricSecurityView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    var body: some View {
        DetailScaffold(title: "Security") {
            VStack(spacing: 12) {
                Image(systemName: session.biometricType.iconName)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.hatchGreen)
                    .frame(width: 92, height: 92)
                    .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
                Text("Biometric Security").font(.title2.weight(.bold))
                Text("Use \(session.biometricName) to unlock HatchPlan Pro. Managers also sign plan approvals with it.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            BiometricSettingsSection()

            Label {
                Text("Authentication happens in the device's Secure Enclave. Biometric data never leaves this phone and is not visible to HatchPlan Pro or its servers.")
            } icon: {
                Image(systemName: "lock.shield.fill").foregroundColor(.hatchGreen)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
        }
    }
}

// MARK: - Password

struct ChangePasswordView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var new = ""
    @State private var confirm = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var succeeded = false

    private var longEnough: Bool { new.count >= 8 }
    private var hasNumberAndSymbol: Bool {
        new.contains(where: \.isNumber) && new.contains(where: { !$0.isLetter && !$0.isNumber })
    }
    private var matches: Bool { !new.isEmpty && new == confirm }
    private var canSave: Bool { !current.isEmpty && longEnough && hasNumberAndSymbol && matches && !isSaving }

    var body: some View {
        DetailScaffold(title: "Change Password") {
            if succeeded {
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.hatchGreen)
                    Text("Password Updated").font(.title2.weight(.bold))
                    Text("Use your new password the next time you sign in.")
                        .foregroundColor(.secondary)
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                Text("Keep your hatchery data secure by updating your password regularly.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                passwordField("CURRENT PASSWORD", text: $current, content: .password)
                passwordField("NEW PASSWORD", text: $new, content: .newPassword)
                passwordField("CONFIRM NEW PASSWORD", text: $confirm, content: .newPassword)

                VStack(alignment: .leading, spacing: 10) {
                    Text("REQUIREMENTS").font(.caption.weight(.bold)).tracking(1.1)
                    requirement("Minimum 8 characters", met: longEnough)
                    requirement("Include numbers and symbols", met: hasNumberAndSymbol)
                    requirement("Passwords must match", met: matches)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14).fill(.white))

                if let errorMessage {
                    AuthErrorBanner(message: errorMessage)
                }

                Button(action: save) {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text("Update Password")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(canSave ? Color.hatchGreen : Color.gray.opacity(0.5)))
                }
                .disabled(!canSave)
            }
        }
    }

    private func passwordField(_ title: String, text: Binding<String>, content: UITextContentType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.bold)).tracking(1).foregroundColor(.hatchOrange)
            SecureField("••••••••", text: text)
                .textContentType(content)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#EDEFF2")))
        }
    }

    private func requirement(_ text: String, met: Bool) -> some View {
        Label(text, systemImage: met ? "checkmark.circle.fill" : "circle")
            .font(.subheadline)
            .foregroundColor(met ? .hatchGreen : .secondary)
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await session.changePassword(current: current, new: new)
                Haptics.notify(.success)
                succeeded = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - User Manual

private struct ManualTopic: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let steps: [String]
}

struct UserManualView: View {
    @State private var query = ""
    @State private var expanded: Set<String> = []

    private let topics: [ManualTopic] = [
        ManualTopic(icon: "sparkles", title: "Getting Started", subtitle: "Accounts, roles and security", steps: [
            "Choose Supervisor or Manager on the welcome screen. Your account is tied to one role.",
            "Turn on Face ID or Touch ID when prompted. Managers need it (or the device passcode) to sign approvals.",
            "Complete your profile in Settings › Profile so your site is pre-selected on new plans."
        ]),
        ManualTopic(icon: "doc.text.viewfinder", title: "Planning a Batch", subtitle: "Scanning certificates and the calculator", steps: [
            "Home › New Plan, then Scan Verified Attached Certificate. Scan with the camera or choose a photo.",
            "The scan fills in batch ID, flock ID, breed, flock age, chick order and customer. Check each field.",
            "Eggs to set = target chicks ÷ breed standard hatchability (adjusted for flock age) × (1 + safety buffer).",
            "Setter trays = eggs ÷ 150. A warning appears if the site's setter capacity would be exceeded."
        ]),
        ManualTopic(icon: "checkmark.seal", title: "Approvals", subtitle: "Manager review and digital signature", steps: [
            "Pending plans appear in Approvals and on the Map, grouped by site.",
            "Review the calculation, source certificate and recent site performance before deciding.",
            "Approve signs with Face ID/Touch ID or passcode. Reject requires a reason that the supervisor sees."
        ]),
        ManualTopic(icon: "calendar.badge.clock", title: "Setting & Incubation", subtitle: "Execute Set, calendar and reminders", steps: [
            "Open an approved batch and tap Execute Set once eggs are physically in the setters.",
            "Candling (day 10), transfer (day 18) and hatch (day 21) are added to Calendar with reminders.",
            "Record floor observations with photos from the batch screen at any time during incubation."
        ]),
        ManualTopic(icon: "chart.bar.doc.horizontal", title: "Closing & Reports", subtitle: "Hatch results and PDF audits", steps: [
            "On hatch day open the batch and tap Log Hatch Results, then enter chicks pulled.",
            "Hatchability and variance against the order and breed standard are calculated automatically.",
            "Generate PDF Report creates a two-page audit you can share by Mail, Files or WhatsApp."
        ]),
        ManualTopic(icon: "wrench.and.screwdriver", title: "Troubleshooting", subtitle: "Sync, scanning and sign-in", steps: [
            "\"Awaiting sync\" means changes are saved on this device and will upload when online and signed in.",
            "If a scan finds few fields, retake it flat, in good light, with the whole certificate in frame.",
            "\"Registered as a Manager/Supervisor\" at sign-in means you chose the other role on the welcome screen."
        ])
    ]

    private var filtered: [ManualTopic] {
        guard !query.isEmpty else { return topics }
        return topics.filter { topic in
            ([topic.title, topic.subtitle] + topic.steps).contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        DetailScaffold(title: "User Manual") {
            VStack(alignment: .leading, spacing: 4) {
                Text("DOCUMENTATION PORTAL").font(.caption.weight(.bold)).tracking(1.2).foregroundColor(.hatchOrange)
                Text("How can we help?").font(.system(size: 30, weight: .bold, design: .rounded))
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search manuals, sensors, or batch tips...", text: $query)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#EDEFF2")))

            if filtered.isEmpty {
                ContentUnavailableView.search(text: query)
            }

            VStack(spacing: 10) {
                ForEach(filtered) { topic in
                    DisclosureGroup(isExpanded: Binding(
                        get: { expanded.contains(topic.title) || !query.isEmpty },
                        set: { if $0 { expanded.insert(topic.title) } else { expanded.remove(topic.title) } }
                    )) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(topic.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(Circle().fill(Color.hatchGreen))
                                    Text(step).font(.subheadline)
                                }
                            }
                        }
                        .padding(.top, 10)
                    } label: {
                        HStack(spacing: 12) {
                            SettingsIcon(icon: topic.icon)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(topic.title).font(.headline).foregroundColor(.primary)
                                Text(topic.subtitle).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(.secondary)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                }
            }
        }
    }
}

// MARK: - Contact Support

struct ContactSupportView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var query = ""
    @State private var showUnavailable = false

    private let faqs: [(String, String)] = [
        ("Why does a batch say \"awaiting sync\"?", "It is saved on this device and uploads automatically once you are online and signed in."),
        ("Can I change a plan after submitting it?", "Not while it is pending. If the manager rejects it, use Revise & Resubmit from the batch."),
        ("Why can't I approve a plan?", "Approvals require Face ID, Touch ID or the device passcode as a digital signature."),
        ("How is the egg quantity calculated?", "Target chicks ÷ breed standard hatchability for the flock's age, plus your safety buffer."),
        ("Where are the calendar milestones?", "In your default iOS calendar after Execute Set, if you allowed Calendar access.")
    ]

    private var filteredFAQs: [(String, String)] {
        query.isEmpty ? faqs : faqs.filter { $0.0.localizedCaseInsensitiveContains(query) || $0.1.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        DetailScaffold(title: "Contact Support") {
            VStack(spacing: 10) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 38))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Circle().fill(Color.white.opacity(0.15)))
                Text("Talk to a Specialist").font(.title2.weight(.bold)).foregroundColor(.white)
                Text("Our poultry specialists help with hatchery planning and app issues. \(SupportContact.hours).")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [.hatchGreenDeep, .hatchGreen], startPoint: .topLeading, endPoint: .bottomTrailing)))

            SettingsSection(title: "DIRECT CHANNELS") {
                channel(icon: "envelope.fill", color: .hatchOrange, title: "Email Support", subtitle: SupportContact.email) {
                    open(mailURL(subject: "HatchPlan Pro support"))
                }
                SettingsDivider()
                channel(icon: "phone.fill", color: Color(hex: "#BB3A63"), title: "Request a Call", subtitle: SupportContact.displayPhone) {
                    open(URL(string: "tel:\(SupportContact.phone)"))
                }
            }

            Button(action: { open(mailURL(subject: "HatchPlan Pro – message from \(session.currentRole.shortTitle)")) }) {
                Label("Send a Message", systemImage: "paperplane.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
            }

            Text("FREQUENTLY ASKED").font(.caption.weight(.bold)).tracking(1.2).foregroundColor(.secondary)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search Help Center...", text: $query)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#EDEFF2")))

            VStack(spacing: 10) {
                ForEach(filteredFAQs, id: \.0) { faq in
                    DisclosureGroup {
                        Text(faq.1).font(.subheadline).foregroundColor(.secondary).padding(.top, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } label: {
                        Text(faq.0).font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                    }
                    .tint(.secondary)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                }
            }

            NavigationLink(destination: UserManualView()) {
                Label("Open the User Manual", systemImage: "book.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.hatchGreen)
            }
        }
        .alert("Not Available on This Device", isPresented: $showUnavailable) {
            Button("Copy Email Address") { UIPasteboard.general.string = SupportContact.email }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Mail or calling isn't set up here. Contact \(SupportContact.email) or \(SupportContact.displayPhone).")
        }
    }

    private func channel(icon: String, color: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SettingsIcon(icon: icon, accent: color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundColor(.secondary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func mailURL(subject: String) -> URL? {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let body = "\n\n—\nRole: \(session.currentRole.rawValue)\nSite: \(session.currentUser.site.name)\nApp version: \(version)\niOS: \(UIDevice.current.systemVersion)"
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = SupportContact.email
        components.queryItems = [URLQueryItem(name: "subject", value: subject), URLQueryItem(name: "body", value: body)]
        return components.url
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        openURL(url) { accepted in
            if !accepted { showUnavailable = true }
        }
    }
}

// MARK: - Legal

struct TermsOfServiceView: View {
    @AppStorage("termsAcceptedAt") private var acceptedAt: Double = 0
    @State private var agreed = false

    private let blocks: [(String, String)] = [
        ("1. Acceptance of Terms", "By creating a HatchPlan Pro account you agree to these terms. If you use the app on behalf of a hatchery, you confirm you are authorised to bind that business."),
        ("2. User Responsibilities", "You are responsible for the accuracy of batch IDs, flock data, chick orders and hatch results you enter, and for keeping your credentials secure."),
        ("3. Decision Support", "Calculations are planning aids based on breed standards. Final setting decisions remain with qualified hatchery staff."),
        ("4. Data Ownership", "Operational data you record remains the property of your hatchery. HatchPlan Pro retains rights to the software and calculation logic."),
        ("5. Limitation of Liability", "To the extent permitted by law, HatchPlan Pro is not liable for losses arising from connectivity outages, user error or incorrect input data.")
    ]

    var body: some View {
        DetailScaffold(title: "Terms of Service") {
            Text("LAST UPDATED: OCTOBER 2026").font(.caption.weight(.bold)).tracking(1).foregroundColor(.hatchOrange)
            ForEach(blocks, id: \.0) { block in
                VStack(alignment: .leading, spacing: 6) {
                    Text(block.0).font(.headline).foregroundColor(.hatchGreen)
                    Text(block.1).font(.subheadline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(.white))
            }

            if acceptedAt > 0 {
                Label("Accepted on \(Date(timeIntervalSince1970: acceptedAt).formatted(date: .long, time: .shortened))",
                      systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.hatchGreen)
            } else {
                Toggle("I have read and agree to the Terms of Service", isOn: $agreed)
                    .font(.subheadline)
                    .tint(.hatchGreen)
                Button("I Accept") {
                    acceptedAt = Date().timeIntervalSince1970
                    Haptics.notify(.success)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(agreed ? Color.hatchGreenDeep : Color.gray.opacity(0.5)))
                .disabled(!agreed)
            }
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        DetailScaffold(title: "Privacy Policy") {
            Text("EFFECTIVE OCT 2026")
                .font(.caption2.weight(.bold))
                .tracking(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.hatchGreenSoft))
            Text("Industrial Data Integrity").font(.system(size: 32, weight: .bold, design: .rounded))
            Text("HatchPlan Pro is built for precision agriculture. Your hatchery's operational data is treated with the same care as the eggs in your setters.")
                .foregroundColor(.secondary)

            card(icon: "tray.full.fill", color: .hatchGreen, title: "What We Store",
                 body: "Batch plans, flock and certificate scans, observations and photos, hatch results, and your profile (name, role, site, contact details).")
            card(icon: "faceid", color: Color(hex: "#8A6B11"), title: "Biometric Security",
                 body: "Face ID and Touch ID are verified on your device. HatchPlan Pro never receives or stores biometric data.")
            card(icon: "icloud.fill", color: Color(hex: "#40483F"), title: "Where It Lives",
                 body: "Data is cached on this device for offline use and synced to the hatchery's Google Firebase project, restricted to signed-in staff.")
            card(icon: "square.and.arrow.up.fill", color: .hatchOrange, title: "Sharing",
                 body: "Nothing is shared with third parties. PDF reports leave the app only when you share them yourself.")
        }
    }

    private func card(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            SettingsIcon(icon: icon, accent: color)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(body).font(.subheadline).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white))
    }
}
