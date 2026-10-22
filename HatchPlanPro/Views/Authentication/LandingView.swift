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
                        ForEach([HatcheryRole.supervisor, .manager]) { role in
                            NavigationLink(destination: RoleOnboardingView(role: role)) {
                                RoleSelectionButton(
                                    title: role.rawValue,
                                    iconName: role.displaySymbol,
                                    subtitle: role.roleSummary,
                                    style: role == .manager ? .manager : .supervisor
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(role.rawValue)
                            .accessibilityHint("Shows the \(role.shortTitle.lowercased()) introduction, then sign in or create an account")
                        }
                    }
                    .padding(.horizontal, 20)

                    Text("New here? Choose your role to create an account.")
                        .font(.footnote)
                        .foregroundColor(.secondary)

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
