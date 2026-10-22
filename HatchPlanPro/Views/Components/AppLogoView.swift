//
//  AppLogoView.swift
//  HatchPlanPro
//
//  Shared HatchPlan logo used across onboarding, landing, and dashboard surfaces.
//

import SwiftUI
import UIKit

struct AppLogoView: View {
    var size: CGFloat = 92
    var title: String? = nil
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.hatchGreenSoft, .white], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: size * 1.25, height: size * 1.25)

                logoImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .accessibilityHidden(true)
            }

            if let title {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.hatchGreen)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var logoImage: Image {
        if let uiImage = UIImage(named: "egg.fill") {
            return Image(uiImage: uiImage)
        }

        return Image(systemName: "egg.fill")
    }
}