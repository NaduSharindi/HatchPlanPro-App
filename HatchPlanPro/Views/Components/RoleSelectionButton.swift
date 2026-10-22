//
//  RoleSelectionButton.swift
//  HatchPlanPro
//

import SwiftUI

struct RoleSelectionButton: View {
    enum Style {
        case supervisor
        case manager
    }

    let title: String
    let iconName: String
    var subtitle: String? = nil
    var style: Style = .supervisor

    private var accentColor: Color {
        style == .manager ? .figmaPrimary : .hatchGreen
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2.weight(.semibold))
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.white.opacity(0.2)))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .opacity(0.9)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .foregroundColor(.white)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: accentColor.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}
