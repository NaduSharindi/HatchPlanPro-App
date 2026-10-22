//
//  AuthViewModel.swift
//  HatchPlanPro
//

import Foundation
import Combine

class AuthViewModel: ObservableObject {

    @Published var pin: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    let maxPinLength = 4

    var isSettingUpPIN: Bool {
        !KeychainHelper.shared.hasPIN
    }

    func enterDigit(_ digit: String) {
        guard pin.count < maxPinLength else { return }
        pin.append(digit)

        if pin.count == maxPinLength {
            if isSettingUpPIN {
                savePIN()
            } else {
                verifyPin()
            }
        }
    }

    func deleteDigit() {
        guard !pin.isEmpty else { return }
        pin.removeLast()
    }

    private func verifyPin() {
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }

            if KeychainHelper.shared.validatePIN(self.pin) {
                self.isAuthenticated = true
                self.errorMessage = nil
            } else {
                self.errorMessage = "Incorrect PIN. Please try again."
                self.showError = true
                self.pin = ""
            }
            self.isLoading = false
        }
    }

    private func savePIN() {
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }

            if KeychainHelper.shared.savePIN(self.pin) {
                self.isAuthenticated = true
                self.errorMessage = nil
            } else {
                self.errorMessage = "Failed to save PIN. Please try again."
                self.showError = true
                self.pin = ""
            }
            self.isLoading = false
        }
    }

    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let biometricService = BiometricAuthService.shared

        guard biometricService.isBiometricAvailable else {
            errorMessage = "\(biometricService.biometricName) is not available on this device."
            showError = true
            completion(false)
            return
        }

        guard biometricService.isEnabled else {
            errorMessage = "Enable \(biometricService.biometricName) first to use biometric sign-in."
            showError = true
            completion(false)
            return
        }

        isLoading = true
        showError = false

        biometricService.authenticate(reason: "Log in to your HatchPlan Pro account securely.") { [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success:
                self.errorMessage = nil
                completion(true)
            case .failure(let error):
                self.errorMessage = biometricService.localizedErrorMessage(from: error)
                self.showError = true
                completion(false)
            }
        }
    }

    func reset() {
        pin = ""
        isAuthenticated = false
        errorMessage = nil
        showError = false
        isLoading = false
    }
}
