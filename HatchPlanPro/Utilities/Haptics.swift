//
//  Haptics.swift
//  HatchPlanPro
//
//  Haptic feedback that honours the Settings › Haptic Feedback preference.
//

import UIKit

enum Haptics {
    static let preferenceKey = "hapticEnabled"

    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: preferenceKey) as? Bool ?? true
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
