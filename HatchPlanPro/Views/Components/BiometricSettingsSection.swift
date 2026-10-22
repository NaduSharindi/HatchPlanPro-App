//
//  BiometricSettingsSection.swift
//  HatchPlanPro
//
//  Shared Face ID / Touch ID opt-in used by both the supervisor and manager
//  security screens so the two workflows behave identically.
//

import SwiftUI

struct BiometricSettingsSection: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @Environment(\.scenePhase) private var scenePhase

    /// Bumped when the app returns to the foreground so enrollment made in iOS
    /// Settings is picked up without leaving and re-entering this screen.
    @State private var availabilityRevision = 0

    private var biometric: BiometricAuthService { .shared }

    var body: some View {
        VStack(spacing: 10) {
            row(for: .faceID)
            row(for: .touchID)

            if let message = session.biometricErrorMessage ?? biometric.unavailableReason {
                BiometricNoticeBanner(message: message,
                                      showsSettingsAction: biometric.shouldOfferSystemSettings) {
                    session.openSystemSettings()
                }
            }
        }
        .id(availabilityRevision)
        .onAppear { session.refreshBiometricState() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            session.refreshBiometricState()
            availabilityRevision += 1
        }
    }

    private func row(for type: BiometricType) -> some View {
        let isSupported = biometric.isSupported(type)

        return BiometricToggleRow(
            type: type,
            isSupported: isSupported,
            isBusy: session.isUpdatingBiometrics && isSupported,
            isOn: Binding(
                get: { isSupported && session.biometricsEnabled },
                set: { session.setBiometricEnabled($0) }
            )
        )
    }
}

/// A single Face ID or Touch ID row. Only the biometric the device actually has
/// is interactive; the other is shown disabled with the reason spelled out.
struct BiometricToggleRow: View {
    let type: BiometricType
    let isSupported: Bool
    let isBusy: Bool
    @Binding var isOn: Bool

    private var subtitle: String {
        guard isSupported else { return "Not available on this device" }
        return isOn ? "On — used to unlock the app" : "Use for app entry"
    }

    private var tint: Color { isSupported ? .hatchGreen : .gray }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tint.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text("Enable \(type.displayName)")
                    .font(.headline)
                    .foregroundColor(isSupported ? .primary : .secondary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isBusy {
                ProgressView().scaleEffect(0.8)
            } else {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.hatchGreen)
                    .disabled(!isSupported)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: "#FAFAFA")))
        .opacity(isSupported ? 1 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Enable \(type.displayName)")
        .accessibilityValue(isSupported ? (isOn ? "On" : "Off") : "Not available on this device")
        .accessibilityHint(isSupported
                           ? "Double tap to \(isOn ? "turn off" : "turn on") \(type.displayName) sign in"
                           : "This device does not have \(type.displayName)")
    }
}

struct BiometricNoticeBanner: View {
    let message: String
    let showsSettingsAction: Bool
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.hatchOrange)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if showsSettingsAction {
                Button(action: onOpenSettings) {
                    Text("Open iOS Settings")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.hatchGreen)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.hatchOrange.opacity(0.1)))
        .accessibilityElement(children: .combine)
    }
}
