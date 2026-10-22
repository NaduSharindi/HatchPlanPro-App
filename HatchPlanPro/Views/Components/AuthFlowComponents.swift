//
//  AuthFlowComponents.swift
//  HatchPlanPro
//
//  Shared onboarding and authentication UI building blocks.
//

import SwiftUI

// MARK: - Onboarding Flow

struct OnboardingFlowView: View {
    let pages: [OnboardingPage]
    let accentColor: Color
    let finishButtonTitle: String
    var showsLogoOnFirstPage: Bool = false
    var onSkip: () -> Void
    var onFinish: () -> Void

    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("Skip", action: onSkip)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                        .accessibilityHint("Skips onboarding and continues")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .frame(height: 44)

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    onboardingPage(page, showLogo: showsLogoOnFirstPage && index == 0)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            pageIndicators
                .padding(.bottom, 24)

            Button(action: advance) {
                Text(currentPage == pages.count - 1 ? finishButtonTitle : "Next")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(accentColor))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
            .accessibilityLabel(currentPage == pages.count - 1 ? finishButtonTitle : "Next page")
        }
    }

    private func onboardingPage(_ page: OnboardingPage, showLogo: Bool) -> some View {
        VStack(spacing: 28) {
            Spacer()

            if showLogo {
                AppLogoView(size: 88)
                    .padding(.bottom, 8)
            }

            ZStack {
                Circle()
                    .fill(page.iconBackground)
                    .frame(width: 200, height: 200)
                Image(systemName: page.systemImage)
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundColor(page.iconTint)
            }
            .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.figmaTextDark)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(currentPage == index ? accentColor : Color.gray.opacity(0.25))
                    .frame(width: currentPage == index ? 28 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    private func advance() {
        if currentPage < pages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            onFinish()
        }
    }
}

// MARK: - Auth chrome

struct AuthBackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.figmaTextDark)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Go back")
            Spacer()
        }
        .padding(.horizontal, 12)
    }
}

struct AuthHeader: View {
    let title: String
    let subtitle: String
    var accentColor: Color = .hatchGreen
    var systemImage: String = "lock.shield.fill"

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(accentColor)
                .padding(20)
                .background(Circle().fill(accentColor.opacity(0.12)))
                .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.figmaTextDark)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
}

struct AuthTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var icon: String = "envelope.fill"
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.caption.weight(.bold))
                .kerning(1.1)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(textContentType)
                        .accessibilityLabel(label)
                } else {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                        .accessibilityLabel(label)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

struct AuthPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var accentColor: Color = .hatchGreen
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.white)
                }
                Text(title)
                    .font(.headline.weight(.bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(accentColor))
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.55)
        .accessibilityLabel(title)
    }
}

struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.red.opacity(0.08)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

struct AuthScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.hatchSurface, Color.white, Color.hatchGreenSoft.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
