//
//  LoginViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import Foundation
import SwiftUI
import Combine

enum AuthFlow: Equatable {
    case splash
    case onboarding
    case loginSelection
    case login
    case registerEmail
    case registerPassword
    case registerPhone
    case registerProfile
    case registerComplete
    case main
}

final class AuthViewModel: ObservableObject {
    @Published var authFlow: AuthFlow = .splash
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Registration fields
    @Published var registerEmail = ""
    @Published var registerPassword = ""
    @Published var registerPasswordConfirm = ""
    @Published var registerCarrier = "SKT"
    @Published var registerPhone = ""
    @Published var registerVerificationCode = ""
    @Published var registerUsername = ""
    @Published var registerName = ""

    // Login fields
    @Published var loginEmail = ""
    @Published var loginPassword = ""

    @Published var currentUser: User?

//    private let authService = AuthService.shared

    var isEmailValid: Bool {
        registerEmail.contains("@") && registerEmail.contains(".")
    }

    var isPasswordValid: Bool {
        registerPassword.count >= 8 && registerPassword == registerPasswordConfirm
    }

    var isPhoneValid: Bool {
        !registerPhone.isEmpty && !registerVerificationCode.isEmpty
    }

    var isProfileValid: Bool {
        !registerUsername.isEmpty && !registerName.isEmpty
    }

    var isLoginValid: Bool {
        !loginEmail.isEmpty && !loginPassword.isEmpty
    }

    @MainActor
    func checkAuthStatus() {
        // Mock: always go to onboarding since no real auth
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.authFlow = .onboarding
        }
    }

    func login() async {
        guard isLoginValid else { return }
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        // Mock: simulate short delay then login
        try? await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            let mockUser = User(
                id: 1,
                email: loginEmail,
                username: "silver_c.ld",
                name: "김은찬",
                profileImageUrl: nil,
                backgroundImageUrl: nil,
                phoneNumber: nil,
                postCount: 5,
                friendCount: 13,
                streakCount: 2
            )
            currentUser = mockUser
            isLoggedIn = true
            authFlow = .main
            isLoading = false
        }
    }

    func register() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        // Mock: simulate short delay then complete registration
        try? await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            let mockUser = User(
                id: 1,
                email: registerEmail,
                username: registerUsername.isEmpty ? "silver_c.ld" : registerUsername,
                name: registerName.isEmpty ? "김은찬" : registerName,
                profileImageUrl: nil,
                backgroundImageUrl: nil,
                phoneNumber: registerPhone,
                postCount: 0,
                friendCount: 0,
                streakCount: 0
            )
            currentUser = mockUser
            authFlow = .registerComplete
            isLoading = false
        }
    }

    @MainActor
    func completeRegistration() {
        isLoggedIn = true
        authFlow = .main
    }

    func logout() async {
        await MainActor.run {
            isLoggedIn = false
            authFlow = .loginSelection
            clearFields()
        }
    }

    private func clearFields() {
        loginEmail = ""
        loginPassword = ""
        registerEmail = ""
        registerPassword = ""
        registerPasswordConfirm = ""
        registerPhone = ""
        registerVerificationCode = ""
        registerUsername = ""
        registerName = ""
    }
}
