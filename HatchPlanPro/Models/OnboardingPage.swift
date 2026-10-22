//
//  OnboardingPage.swift
//  HatchPlanPro
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let description: String
    var iconTint: Color = .hatchGreen
    var iconBackground: Color = .hatchGreenSoft
}

enum AppOnboardingContent {
    static let welcomePages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "egg.fill",
            title: "Welcome to HatchPlan Pro",
            description: "Your intelligent hatchery command centre for supervisors and managers.",
            iconTint: .hatchGreen,
            iconBackground: .hatchGreenSoft
        ),
        OnboardingPage(
            systemImage: "thermometer.medium",
            title: "Monitor Every Batch",
            description: "Track temperature, humidity, and incubation progress across every room in real time.",
            iconTint: .hatchOrange,
            iconBackground: .hatchOrangeSoft
        ),
        OnboardingPage(
            systemImage: "bell.badge.fill",
            title: "Act on Critical Alerts",
            description: "Receive instant notifications when batches need attention or manager approval.",
            iconTint: .hatchGreen,
            iconBackground: .hatchGreenSoft
        )
    ]

    static let supervisorPages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "chart.line.uptrend.xyaxis",
            title: "Supervisor Dashboard",
            description: "See today's hatch schedule, live counts, and facility health at a glance.",
            iconTint: .hatchGreen,
            iconBackground: .hatchGreenSoft
        ),
        OnboardingPage(
            systemImage: "camera.viewfinder",
            title: "Scan & Record Batches",
            description: "Capture batch labels, log observations, and submit hatch plans for approval.",
            iconTint: .hatchOrange,
            iconBackground: .hatchOrangeSoft
        ),
        OnboardingPage(
            systemImage: "lock.shield.fill",
            title: "Secure Field Access",
            description: "Sign in with email, biometrics, or PIN so only authorised staff reach hatchery data.",
            iconTint: .hatchGreen,
            iconBackground: .hatchGreenSoft
        )
    ]
}
