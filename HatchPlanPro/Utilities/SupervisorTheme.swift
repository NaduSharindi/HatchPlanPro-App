//
//  SupervisorTheme.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-12.
//

import SwiftUI

extension Color {
    static let hatchGreen = Color(hex: "#245B24")
    static let hatchGreenDeep = Color(hex: "#143814")
    static let hatchGreenSoft = Color(hex: "#EAF3EA")
    static let hatchOrange = Color(hex: "#B78900")
    static let hatchOrangeSoft = Color(hex: "#F7E7B6")
    static let hatchSurface = Color(hex: "#F7F7FA")
}

struct SupervisorCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
            )
    }
}

extension View {
    func supervisorCard() -> some View {
        modifier(SupervisorCardStyle())
    }
}
