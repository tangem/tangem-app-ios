//
//  MobileOnboardingICloudBackupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemMobileWalletSdk
import TangemMobileWalletBackup
import TangemAssets
import TangemLocalization
import TangemUIUtils

final class MobileOnboardingICloudBackupViewModel: ObservableObject {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    @Published private(set) var state: State = .setPassword
    @Published private(set) var isPasswordSecured: Bool = true

    @Published var passwordText: String = .empty
    @Published var isPasswordResponder: Bool? = true
    @Published var isPasswordWarningAccepted: Bool = false

    let navigationTitle = Localization.hwBackupIcloudTitle
    let infoDescription = "A password is required to encrypt your secret phrase on iCloud."

    var leadingNavBarAction: MobileOnboardingFlowNavBarAction? {
        makeLeadingNavBarAction()
    }

    var trailingNavBarAction: MobileOnboardingFlowNavBarAction {
        makeTrailingNavBarAction()
    }

    var infoTitle: String {
        switch state {
        case .setPassword: "Set password"
        case .confirmPassword: "Confirm password"
        }
    }

    var passwordStrength: PasswordStrength {
        calculatePasswordStrength()
    }

    var passwordMatching: PasswordMatching {
        calculatePasswordMatching()
    }

    var isPasswordWarningVisible: Bool {
        switch state {
        case .setPassword: false
        case .confirmPassword: true
        }
    }

    var actionTitle: String {
        switch state {
        case .setPassword: "Set password"
        case .confirmPassword: "Confirm"
        }
    }

    var isActionEnabled: Bool {
        switch state {
        case .setPassword:
            passwordStrength == .strong
        case .confirmPassword:
            isPasswordWarningAccepted && isPasswordMatched
        }
    }

    private var isPasswordMatched: Bool {
        passwordMatching == .matched
    }

    private lazy var authUtil = MobileAuthUtil(
        userWalletId: userWalletModel.userWalletId,
        config: userWalletModel.config,
        biometricsProvider: CommonUserWalletBiometricsProvider()
    )

    private lazy var backupManager = CommonMobileWalletBackupManager(
        destination: .iCloud
    )

    private let passwordValidator = MobileWalletBackupPasswordValidator()

    private let userWalletModel: UserWalletModel
    private weak var delegate: MobileOnboardingICloudBackupDelegate?

    init(userWalletModel: UserWalletModel, delegate: MobileOnboardingICloudBackupDelegate) {
        self.userWalletModel = userWalletModel
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension MobileOnboardingICloudBackupViewModel {
    func onPasswordSecurityTap() {
        isPasswordSecured.toggle()
    }

    func onPasswordWarningTap() {
        isPasswordWarningAccepted.toggle()
    }

    func onActionTap() {
        switch state {
        case .setPassword:
            setupConfirmPasswordState()
        case .confirmPassword(let password):
            backup(password: password)
        }
    }

    func onDisappear() {
        eraseState()
    }
}

// MARK: - NavBar

private extension MobileOnboardingICloudBackupViewModel {
    func makeLeadingNavBarAction() -> MobileOnboardingFlowNavBarAction? {
        switch state {
        case .setPassword:
            return nil
        case .confirmPassword:
            let backHandler: () -> Void = { [weak self] in
                self?.resetToSetPasswordState()
            }
            return .back(handler: backHandler)
        }
    }

    func makeTrailingNavBarAction() -> MobileOnboardingFlowNavBarAction {
        let closeHandler: () -> Void = { [weak self] in
            Task {
                await self?.showDismissAlert()
            }
        }
        return .close(style: .button, handler: closeHandler)
    }
}

// MARK: - Backup

private extension MobileOnboardingICloudBackupViewModel {
    func backup(password: String) {
        Task {
            let unlockResult = await unlock()
            switch unlockResult {
            case .successful(let context):
                await makeBackup(password: password, context: context)
            case .failed(let error):
                await showErrorAlert(error)
            case .canceled:
                break
            }
        }
    }

    func makeBackup(password: String, context: MobileWalletContext) async {
        do {
            try await backupManager.createBackup(
                context: context,
                walletName: userWalletModel.name,
                walletId: userWalletModel.userWalletId,
                password: password
            )

            markBackupCompleted()
            await onComplete()

        } catch {
            return await showErrorAlert(error)
        }
    }

    func markBackupCompleted() {
        userWalletModel.update(type: .iCloudBackupCompleted)
    }

    func unlock() async -> UnlockResult {
        do {
            let result = try await authUtil.unlock()

            switch result {
            case .successful(let context):
                return .successful(context: context)

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
                return .canceled
            }

        } catch {
            return .failed(error: error)
        }
    }

    enum UnlockResult {
        case successful(context: MobileWalletContext)
        case canceled
        case failed(error: Error)
    }
}

// MARK: - State

private extension MobileOnboardingICloudBackupViewModel {
    func resetToSetPasswordState() {
        guard case .confirmPassword(let password) = state else {
            return
        }
        state = .setPassword
        passwordText = password
    }

    func setupConfirmPasswordState() {
        state = .confirmPassword(passwordText)
        resetPassword()
    }

    func eraseState() {
        state = .setPassword
        resetPassword()
    }

    func resetPassword() {
        passwordText = .empty
    }
}

// MARK: - Helpers

private extension MobileOnboardingICloudBackupViewModel {
    func calculatePasswordStrength() -> PasswordStrength {
        guard passwordText.isNotEmpty else {
            return .none
        }

        switch passwordValidator.validate(passwordText).strength {
        case .weak: return .weak
        case .medium: return .average
        case .strong: return .strong
        }
    }

    func calculatePasswordMatching() -> PasswordMatching {
        guard
            passwordText.isNotEmpty,
            case .confirmPassword(let confirmablePassword) = state
        else {
            return .none
        }

        return passwordText == confirmablePassword ? .matched : .notMatched
    }
}

// MARK: - Alerts

@MainActor
private extension MobileOnboardingICloudBackupViewModel {
    func showDismissAlert() {
        let alert = AlertBuilder.makeAlert(
            title: "Cancel backup setup?",
            message: "Your wallet won't be backed up to iCloud. You can set this up later in wallet settings.",
            primaryButton: .cancel(Text("Continue backup")),
            secondaryButton: .destructive(
                Text("Cancel backup"),
                action: weakify(self, forFunction: MobileOnboardingICloudBackupViewModel.onClose)
            )
        )
        showAlert(alert)
    }

    func showErrorAlert(_ error: Error) {
        let alert = error.alertBinder
        showAlert(alert)
    }

    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }
}

// MARK: - Navigation

@MainActor
private extension MobileOnboardingICloudBackupViewModel {
    func onComplete() {
        delegate?.onICloudBackupComplete()
    }

    func onClose() {
        delegate?.onICloudBackupClose()
    }
}

// MARK: - Types

extension MobileOnboardingICloudBackupViewModel {
    enum State {
        case setPassword
        case confirmPassword(String)
    }

    enum PasswordStrength {
        case none
        case weak
        case average
        case strong

        var description: String {
            switch self {
            case .none: "Password strength"
            case .weak: "Weak password"
            case .average: "Average password"
            case .strong: "Strong password"
            }
        }

        var color: Color {
            switch self {
            case .none: DesignSystem.Color.textSecondary
            case .weak: DesignSystem.Color.textStatusError
            case .average: DesignSystem.Color.textStatusWarning
            case .strong: DesignSystem.Color.textStatusInfo
            }
        }

        var progress: Double? {
            switch self {
            case .none: nil
            case .weak: 0.25
            case .average: 0.75
            case .strong: 1
            }
        }
    }

    enum PasswordMatching {
        case none
        case matched
        case notMatched

        var description: String? {
            switch self {
            case .none, .matched: nil
            case .notMatched: "Password doesn’t match"
            }
        }

        var color: Color {
            switch self {
            case .none: DesignSystem.Color.borderBrand
            case .matched: DesignSystem.Color.borderTertiary
            case .notMatched: DesignSystem.Color.borderStatusError
            }
        }
    }
}
