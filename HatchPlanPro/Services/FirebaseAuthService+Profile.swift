//
//  FirebaseAuthService+Profile.swift
//  HatchPlanPro
//
//  Role-bearing user profiles in Firestore users/{uid}, and account
//  password changes.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

extension FirebaseAuthService {
    /// Loads the stored profile. Returns nil when the account has no profile
    /// document yet (e.g. created in the Firebase console).
    func loadProfile(uid: String, email: String) async throws -> HatcheryUserProfile? {
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        guard let data = snapshot.data(),
              let roleRaw = data["role"] as? String,
              let role = HatcheryRole(rawValue: roleRaw) else { return nil }

        return HatcheryUserProfile(
            fullName: data["fullName"] as? String ?? (currentUser?.displayName ?? ""),
            email: data["email"] as? String ?? email,
            role: role,
            preferredSecurity: "Password",
            uid: uid,
            jobTitle: data["jobTitle"] as? String ?? "",
            employeeID: data["employeeID"] as? String ?? "",
            siteID: data["siteID"] as? String ?? HatcherySite.all[0].id,
            phone: data["phone"] as? String ?? "",
            photoData: data["photo"] as? Data
        )
    }

    func saveProfile(_ profile: HatcheryUserProfile) async throws {
        guard let uid = profile.uid ?? currentUser?.uid else {
            throw NSError(domain: "FirebaseAuthService", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Sign in again to update your profile."])
        }
        var data: [String: Any] = [
            "uid": uid,
            "email": profile.email,
            "fullName": profile.fullName,
            "role": profile.role.rawValue,
            "jobTitle": profile.jobTitle,
            "employeeID": profile.employeeID,
            "siteID": profile.siteID,
            "phone": profile.phone,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        data["photo"] = profile.photoData ?? FieldValue.delete()
        try await Firestore.firestore().collection("users").document(uid).setData(data, merge: true)

        if let user = currentUser, user.displayName != profile.fullName {
            let change = user.createProfileChangeRequest()
            change.displayName = profile.fullName
            try await change.commitChanges()
        }
    }

    /// Re-authenticates with the current password, then sets the new one.
    func changePassword(current: String, new: String) async throws {
        guard let user = currentUser, let email = user.email else {
            throw NSError(domain: "FirebaseAuthService", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Sign in again to change your password."])
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: current)
        try await user.reauthenticate(with: credential)
        try await user.updatePassword(to: new)
    }
}
