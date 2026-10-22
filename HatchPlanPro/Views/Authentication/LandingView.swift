//
//  LandingView.swift
//  HatchPlanPro
//

import SwiftUI

struct LandingView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AuthScreenBackground()

                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 10) {
                        AppLogoView(size: 96, title: "HatchPlan Pro", subtitle: "Precision poultry management")
                        Text("Choose your role to sign in")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 16) {
                        NavigationLink(destination: SupervisorOnboardingView()) {
                            RoleSelectionButton(
                                title: HatcheryRole.supervisor.rawValue,
                                iconName: HatcheryRole.supervisor.displaySymbol,
                                subtitle: "Monitor batches, scan labels, submit plans"
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Hatchery Supervisor")
                        .accessibilityHint("View supervisor onboarding and sign in")

                        NavigationLink(destination: LoginView(role: .manager)) {
                            RoleSelectionButton(
                                title: HatcheryRole.manager.rawValue,
                                iconName: HatcheryRole.manager.displaySymbol,
                                subtitle: "Approve plans, review alerts, run reports",
                                style: .manager
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Hatchery Manager")
                        .accessibilityHint("Sign in to the manager dashboard")
                    }
                    .padding(.horizontal, 20)

                    NavigationLink(destination: SignUpView(role: .supervisor)) {
                        Text("New here? Create an account")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.hatchGreen)
                    }
                    .accessibilityLabel("Create account")

                    Spacer()
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(AppSessionViewModel())
}
