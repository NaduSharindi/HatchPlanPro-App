//
//  KeychainHelper.swift
//  HatchPlanPro
//
//  Provides a secure wrapper around the iOS Keychain for storing
//  sensitive user credentials such as PINs and authentication tokens.
//  This avoids storing secrets in UserDefaults (which is not encrypted).
//

import Foundation
import Security

/// A lightweight, reusable Keychain helper for storing and retrieving
/// small pieces of sensitive data (PIN, uid, biometric preference flag).
final class KeychainHelper {
    
    // MARK: - Singleton
    static let shared = KeychainHelper()
    private init() {}
    
    // MARK: - Keychain Keys
    /// Key used to store the user's 4-digit PIN
    static let pinKey = "com.hatchplanpro.userPIN"
    /// Key used to store whether biometric auth is enabled
    static let biometricEnabledKey = "com.hatchplanpro.biometricEnabled"
    /// Key used to store the Firebase UID for quick offline access
    static let userUIDKey = "com.hatchplanpro.userUID"
    /// Key used to store the user's email for offline access
    static let userEmailKey = "com.hatchplanpro.userEmail"
    /// Key used to store the user's selected role
    static let userRoleKey = "com.hatchplanpro.userRole"
    /// Key used to store the user's full name
    static let userNameKey = "com.hatchplanpro.userName"
    
    // MARK: - Save
    
    /// Saves a string value securely in the Keychain.
    /// - Parameters:
    ///   - value: The string to store.
    ///   - key: The Keychain key identifier.
    /// - Returns: `true` if the save was successful.
    @discardableResult
    func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete any existing item first to avoid duplicates
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add the new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Read
    
    /// Retrieves a string value from the Keychain.
    /// - Parameter key: The Keychain key identifier.
    /// - Returns: The stored string, or `nil` if not found.
    func read(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    // MARK: - Delete
    
    /// Removes a value from the Keychain.
    /// - Parameter key: The Keychain key identifier.
    /// - Returns: `true` if the delete was successful.
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Convenience Methods
    
    /// Saves the user's PIN securely.
    func savePIN(_ pin: String) -> Bool {
        return save(pin, forKey: KeychainHelper.pinKey)
    }
    
    /// Retrieves the stored PIN.
    func getSavedPIN() -> String? {
        return read(forKey: KeychainHelper.pinKey)
    }
    
    /// Checks if a PIN has been set.
    var hasPIN: Bool {
        return getSavedPIN() != nil
    }
    
    /// Validates a PIN against the stored one.
    func validatePIN(_ pin: String) -> Bool {
        guard let savedPIN = getSavedPIN() else { return false }
        return savedPIN == pin
    }
    
    /// Saves the biometric preference flag.
    func setBiometricEnabled(_ enabled: Bool) {
        save(enabled ? "true" : "false", forKey: KeychainHelper.biometricEnabledKey)
    }
    
    /// Reads the biometric preference flag.
    var isBiometricEnabled: Bool {
        return read(forKey: KeychainHelper.biometricEnabledKey) == "true"
    }
    
    /// Saves user session data after successful Firebase authentication.
    func saveUserSession(uid: String, email: String, name: String, role: String) {
        save(uid, forKey: KeychainHelper.userUIDKey)
        save(email, forKey: KeychainHelper.userEmailKey)
        save(name, forKey: KeychainHelper.userNameKey)
        save(role, forKey: KeychainHelper.userRoleKey)
    }
    
    /// Clears all stored credentials on sign out.
    func clearAll() {
        delete(forKey: KeychainHelper.pinKey)
        delete(forKey: KeychainHelper.biometricEnabledKey)
        delete(forKey: KeychainHelper.userUIDKey)
        delete(forKey: KeychainHelper.userEmailKey)
        delete(forKey: KeychainHelper.userNameKey)
        delete(forKey: KeychainHelper.userRoleKey)
    }
}
