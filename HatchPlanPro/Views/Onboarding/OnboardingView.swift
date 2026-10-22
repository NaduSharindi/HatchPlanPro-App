//
//  OnboardingView.swift
//  HatchPlanPro
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    var body: some View {
        ZStack {
            AuthScreenBackground()

            OnboardingFlowView(
                pages: AppOnboardingContent.welcomePages,
                accentColor: .figmaPrimary,
                finishButtonTitle: "Get Started",
                showsLogoOnFirstPage: true,
                onSkip: completeOnboarding,
                onFinish: completeOnboarding
            )
        }
    }

    private func completeOnboarding() {
        hasSeenOnboarding = true
    }
}

#Preview {
    OnboardingView()
}
