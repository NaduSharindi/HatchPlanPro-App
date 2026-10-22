//
//  FirebaseAuthService.swift
//  HatchPlanPro
//
//  Centralises all Firebase Authentication operations: sign-in, sign-up,
//  sign-out, password reset, and auth state monitoring. Every view model
//  interacts with Firebase Auth exclusively through this service to keep
//  concerns separated and the code testable.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Completion alias for auth results.
typealias AuthResultCompletion = (Result<User, Error>) -> Void

/// Handles all Firebase Authentication operations for HatchPlan Pro.
/// Supports email/password authentication with role-based user profiles
/// stored in Firestore alongside the Auth record.
final class FirebaseAuthService {
    
    // MARK: - Singleton
    static let shared = FirebaseAuthService()
    private init() {}
    
    /// The currently authenticated Firebase user, if any.
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    /// Whether a user is currently signed in.
    var isSignedIn: Bool {
        return currentUser != nil
    }
    
    // MARK: - Sign Up
    
    /// Creates a new user account with email and password.
    /// On success, also writes the user profile to Firestore.
    /// - Parameters:
    ///   - email: User's email address.
    ///   - password: User's chosen password (min 6 characters).
    ///   - fullName: User's display name.
    ///   - role: The hatchery role (manager or supervisor).
    ///   - completion: Called on the main thread with the result.
    func signUp(email: String,
                password: String,
                fullName: String,
                role: HatcheryRole,
                completion: @escaping AuthResultCompletion) {
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let user = authResult?.user else {
                let noUserError = NSError(
                    domain: "FirebaseAuthService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Account created but no user returned."]
                )
                DispatchQueue.main.async { completion(.failure(noUserError)) }
                return
            }
            
            // Update the display name on the Firebase Auth profile
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            changeRequest.commitChanges { _ in
                // Write the extended profile to Firestore
                self.saveUserProfile(
                    uid: user.uid,
                    email: email,
                    fullName: fullName,
                    role: role
                )
                
                // Save session to Keychain for offline access
                KeychainHelper.shared.saveUserSession(
                    uid: user.uid,
                    email: email,
                    name: fullName,
                    role: role.rawValue
                )
                
                DispatchQueue.main.async { completion(.success(user)) }
            }
        }
    }
    
    // MARK: - Sign In
    
    /// Signs in an existing user with email and password.
    /// - Parameters:
    ///   - email: User's email address.
    ///   - password: User's password.
    ///   - completion: Called on the main thread with the result.
    func signIn(email: String,
                password: String,
                completion: @escaping AuthResultCompletion) {
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let user = authResult?.user else {
                let noUserError = NSError(
                    domain: "FirebaseAuthService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Sign-in succeeded but no user returned."]
                )
                DispatchQueue.main.async { completion(.failure(noUserError)) }
                return
            }
            
            // Update Keychain with current session
            KeychainHelper.shared.saveUserSession(
                uid: user.uid,
                email: email,
                name: user.displayName ?? "",
                role: KeychainHelper.shared.read(forKey: KeychainHelper.userRoleKey) ?? ""
            )
            
            DispatchQueue.main.async { completion(.success(user)) }
        }
    }
    
    // MARK: - Sign Out
    
    /// Signs out the current user and clears the Keychain session.
    /// - Returns: `true` if sign-out was successful.
    @discardableResult
    func signOut() -> Bool {
        do {
            try Auth.auth().signOut()
            // Don't clear PIN/biometric prefs on sign-out — only clear session
            KeychainHelper.shared.delete(forKey: KeychainHelper.userUIDKey)
            return true
        } catch {
            print("FirebaseAuthService: Sign-out failed — \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Password Reset
    
    /// Sends a password-reset email to the specified address.
    /// - Parameters:
    ///   - email: The email to send the reset link to.
    ///   - completion: Called on the main thread with success or failure.
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Auth State Listener
    
    /// Attaches a listener that fires whenever the auth state changes
    /// (user signs in or out).
    /// - Parameter handler: Called on the main thread with the current user (or nil).
    /// - Returns: A handle that can be used to remove the listener.
    @discardableResult
    func addAuthStateListener(_ handler: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle {
        return Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                handler(user)
            }
        }
    }
    
    /// Removes a previously attached auth state listener.
    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }
    
    // MARK: - Firestore User Profile
    
    /// Persists the user profile to Firestore for cross-device access
    /// and role-based data retrieval.
    private func saveUserProfile(uid: String, email: String, fullName: String, role: HatcheryRole) {
        let db = FirebaseFirestore.Firestore.firestore()
        let profileData: [String: Any] = [
            "uid": uid,
            "email": email,
            "fullName": fullName,
            "role": role.rawValue,
            "createdAt": FirebaseFirestore.FieldValue.serverTimestamp(),
            "biometricEnabled": false,
            "pinConfigured": false
        ]
        
        db.collection("users").document(uid).setData(profileData, merge: true) { error in
            if let error = error {
                print("FirebaseAuthService: Failed to save user profile — \(error.localizedDescription)")
            }
        }
    }
    
    /// Fetches the user profile from Firestore.
    /// - Parameters:
    ///   - uid: The Firebase UID.
    ///   - completion: Called on the main thread with the profile dictionary.
    func fetchUserProfile(uid: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let db = FirebaseFirestore.Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else if let data = snapshot?.data() {
                    completion(.success(data))
                } else {
                    completion(.failure(NSError(
                        domain: "FirebaseAuthService",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "User profile not found."]
                    )))
                }
            }
        }
    }
}

