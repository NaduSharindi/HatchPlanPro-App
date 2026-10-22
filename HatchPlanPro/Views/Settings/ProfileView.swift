//
//  ProfileView.swift
//  HatchPlanPro
//
//  Account details for both roles, editable and synced to Firestore.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var draft: HatcheryUserProfile?
    @State private var photoItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSignOutConfirm = false

    private var isEditing: Bool { draft != nil }
    private var profile: HatcheryUserProfile { draft ?? session.currentUser }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(title: "Account Details") {
                    Button(isEditing ? "Cancel" : "Edit") {
                        draft = isEditing ? nil : session.currentUser
                        errorMessage = nil
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.hatchGreen)
                }

                VStack(spacing: 8) {
                    ZStack(alignment: .bottomTrailing) {
                        ProfileAvatar(profile: profile, size: 110)
                        if isEditing {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                Image(systemName: "camera.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white)
                                    .frame(width: 34, height: 34)
                                    .background(Circle().fill(Color.hatchGreen))
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                            }
                            .accessibilityLabel("Change profile photo")
                        }
                    }
                    if isEditing, profile.photoData != nil {
                        Button("Remove Photo", role: .destructive) { draft?.photoData = nil }
                            .font(.caption)
                    }
                    Text(profile.fullName).font(.title2.weight(.bold))
                    Text(profile.displayTitle.uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundColor(.hatchGreen.opacity(0.75))
                }
                .frame(maxWidth: .infinity)

                if isEditing {
                    editForm
                } else {
                    details
                }

                if let errorMessage { AuthErrorBanner(message: errorMessage) }

                if isEditing {
                    Button(action: save) {
                        HStack {
                            if isSaving { ProgressView().tint(.white) }
                            Text("Save Changes")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.hatchGreen))
                    }
                    .disabled(isSaving || profile.fullName.trimmingCharacters(in: .whitespaces).isEmpty)
                } else {
                    Button(role: .destructive, action: { showSignOutConfirm = true }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.1)))
                    }
                }

                Text("Your professional details are used for secure access logging and audit trails within the facility.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.hatchSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    draft?.photoData = CertificateOCRService.compressedRecord(of: image, maxDimension: 320)
                }
                photoItem = nil
            }
        }
        .confirmationDialog("Sign out of HatchPlan Pro?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { session.signOut() }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(title: "FACILITY DETAILS") {
                detailRow(icon: "mappin.circle", title: "HATCHERY LOCATION", value: profile.site.name)
                SettingsDivider()
                detailRow(icon: "person.text.rectangle", title: "EMPLOYEE ID", value: profile.employeeID.isEmpty ? "Not set" : profile.employeeID)
                SettingsDivider()
                detailRow(icon: "briefcase", title: "ROLE", value: profile.role.rawValue)
            }
            SettingsSection(title: "CONTACT INFORMATION") {
                detailRow(icon: "envelope", title: "EMAIL", value: profile.email)
                SettingsDivider()
                detailRow(icon: "phone", title: "PHONE NUMBER", value: profile.phone.isEmpty ? "Not set" : profile.phone)
            }
            SettingsSection(title: "SECURITY") {
                detailRow(icon: "lock.shield", title: "SIGN-IN METHOD", value: session.biometricsEnabled ? "Password + \(session.biometricName)" : "Password")
            }
        }
    }

    private var editForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(title: "PROFESSIONAL DETAILS") {
                field("Full Name", text: binding(\.fullName), content: .name)
                SettingsDivider()
                field("Job Title", text: binding(\.jobTitle), placeholder: "Senior Hatchery Lead", content: .jobTitle)
                SettingsDivider()
                field("Employee ID", text: binding(\.employeeID), placeholder: "HP-99234-X")
            }
            SettingsSection(title: "FACILITY DETAILS") {
                HStack {
                    Text("Hatchery Location").font(.subheadline)
                    Spacer()
                    Picker("Hatchery Location", selection: binding(\.siteID)) {
                        ForEach(HatcherySite.all) { Text($0.name).tag($0.id) }
                    }
                    .labelsHidden()
                    .tint(.hatchGreen)
                }
                .padding(14)
            }
            SettingsSection(title: "CONTACT INFORMATION") {
                HStack {
                    Text("Email").font(.subheadline)
                    Spacer()
                    Text(profile.email).font(.subheadline).foregroundColor(.secondary)
                }
                .padding(14)
                SettingsDivider()
                field("Phone Number", text: binding(\.phone), placeholder: "+94 77 123 4567", content: .telephoneNumber, keyboard: .phonePad)
            }
        }
    }

    private func binding(_ keyPath: WritableKeyPath<HatcheryUserProfile, String>) -> Binding<String> {
        Binding(get: { draft?[keyPath: keyPath] ?? "" }, set: { draft?[keyPath: keyPath] = $0 })
    }

    private func field(_ title: String, text: Binding<String>, placeholder: String = "", content: UITextContentType? = nil,
                       keyboard: UIKeyboardType = .default) -> some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer(minLength: 16)
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .textContentType(content)
                .keyboardType(keyboard)
        }
        .padding(14)
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.hatchGreen).frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption2.weight(.bold)).foregroundColor(.secondary)
                Text(value).font(.body)
            }
            Spacer()
        }
        .padding(14)
        .accessibilityElement(children: .combine)
    }

    private func save() {
        guard let draft else { return }
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await session.updateProfile(draft)
                Haptics.notify(.success)
                self.draft = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
