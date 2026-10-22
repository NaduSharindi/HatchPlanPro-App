//
//  SupervisorProfileView.swift
//  HatchPlanPro
//

import SwiftUI

struct SupervisorProfileView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                ProfileDetailHeader(title: "Supervisor Profile")

                VStack(spacing: 10) {
                    Circle()
                        .fill(LinearGradient(colors: [.hatchGreenSoft, .white], startPoint: .top, endPoint: .bottom))
                        .frame(width: 118, height: 118)
                        .overlay(Image(systemName: "person.fill").font(.system(size: 44, weight: .semibold)).foregroundColor(.hatchGreen))

                    Text(session.currentUser.fullName)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(session.currentUser.email)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))

                VStack(alignment: .leading, spacing: 12) {
                    Text("PROFILE DETAILS")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundColor(.secondary)

                    profileRow(title: "Role", value: session.currentUser.role.rawValue)
                    profileRow(title: "Security", value: session.currentUser.preferredSecurity)
                    profileRow(title: "Location", value: "Meegoda Hatchery")
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))

                Button(action: { session.signOut() }) {
                    Text("Sign Out")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.red.opacity(0.1)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func profileRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 6)
    }
}

private struct ProfileDetailHeader: View {
    @Environment(\.dismiss) private var dismiss
    let title: String

    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.hatchGreen)
                    .frame(width: 42, height: 42)
            }
            Spacer()
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.hatchGreen)
            Spacer()
            Color.clear
                .frame(width: 42, height: 42)
        }
        .padding(.horizontal, 4)
    }
}