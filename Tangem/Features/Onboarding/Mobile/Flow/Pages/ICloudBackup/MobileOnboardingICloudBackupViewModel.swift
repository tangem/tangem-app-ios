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
    fileprivate typealias Validator = MobileWalletBackupPasswordValidator

    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    @Published private(set) var state: State = .setPassword
    @Published private(set) var isPasswordSecured: Bool = true

    @Published var passwordText: String = .empty
    @Published var isPasswordResponder: Bool? = true
    @Published var isPasswordWarningAccepted: Bool = false

    let navigationTitle = Localization.hwBackupIcloudTitle
    let passwordTitle = Localization.hwCloudBackupPasswordHint
    let passwordWarningTitle = Localization.hwCloudBackupConsent

    var leadingNavBarAction: MobileOnboardingFlowNavBarAction? {
        makeLeadingNavBarAction()
    }

    var trailingNavBarAction: MobileOnboardingFlowNavBarAction {
        makeTrailingNavBarAction()
    }

    var infoTitle: String {
        switch state {
        case .setPassword: Localization.hwCloudBackupSetPasswordTitle
        case .confirmPassword: Localization.hwCloudBackupConfirmPasswordTitle
        }
    }

    var infoDescription: String {
        switch state {
        case .setPassword: Localization.hwCloudBackupSetPasswordDescription(MobileBackupConstants.iCloudServiceName)
        case .confirmPassword: Localization.hwCloudBackupConfirmPasswordDescription(MobileBackupConstants.iCloudServiceName)
        }
    }

    var passwordStrengthInfo: PasswordStrengthInfo {
        passwordStrengthInfo(validation: passwordValidation)
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
        case .setPassword: Localization.hwCloudBackupSetPasswordButton
        case .confirmPassword: Localization.commonConfirm
        }
    }

    var isActionEnabled: Bool {
        switch state {
        case .setPassword:
            passwordValidation.strength == .strong
        case .confirmPassword:
            isPasswordWarningAccepted && isPasswordMatched
        }
    }

    private var passwordValidation: Validator.Validation {
        passwordValidator.validate(passwordText)
    }

    private var isPasswordMatched: Bool {
        passwordMatching == .matched
    }

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private lazy var authUtil = MobileAuthUtil(
        userWalletId: userWalletModel.userWalletId,
        config: userWalletModel.config,
        biometricsProvider: CommonUserWalletBiometricsProvider()
    )

    private lazy var backupManager = CommonMobileWalletBackupManager(
        destination: .iCloud
    )

    private let passwordValidator = Validator()

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

    func onSetPasswordAppear() {
        logSetPasswordScreenAnalytics()
    }

    func onConfirmPasswordAppear() {
        logConfirmPasswordScreenAnalytics()
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
            self?.onNavBarCloseTap()
        }
        return .close(style: .button, handler: closeHandler)
    }

    func onNavBarCloseTap() {
        let shouldSkipDismissAlert = state == .setPassword && passwordText.isEmpty

        runTask(in: self) { viewModel in
            if shouldSkipDismissAlert {
                await viewModel.close()
            } else {
                await viewModel.showDismissAlert()
            }
        }
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
                logCreationErrorAnalytics(error)
                await showErrorAlert(error)
            case .canceled:
                break
            }
        }
    }

    func makeBackup(password: String, context: MobileWalletContext) async {
        do {
            let backup = try await backupManager.createBackup(
                context: context,
                walletName: userWalletModel.name,
                walletId: userWalletModel.userWalletId,
                password: password
            )

            markBackupCompleted()
            logBackupFinishedAnalytics()

            let user = backup.metadata.fileNameWithoutSuffix

            do {
                let savedCredential = try WebCredentialUtil.SavedCredential(
                    user: user,
                    password: password
                )
                await complete(savedCredential: savedCredential)
            } catch {
                AppLogger.error("Failed to create web credential", error: error)
                await complete(savedCredential: nil)
            }

        } catch {
            logCreationErrorAnalytics(error)
            switch error {
            case WalletBackupStorageError.storageUnavailable:
                await delegate?.onICloudUnavailable()
            default:
                await showErrorAlert(error)
            }
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
    func passwordStrengthInfo(validation: Validator.Validation) -> PasswordStrengthInfo {
        let strength = validation.strength

        let title = switch strength {
        case .none: Localization.hwCloudBackupStrengthNone
        case .weak: Localization.hwCloudBackupStrengthWeak
        case .medium: Localization.hwCloudBackupStrengthMedium
        case .strong: Localization.hwCloudBackupStrengthStrong
        }

        let description = passwordHint(validation: validation)

        let color = switch strength {
        case .none: DesignSystem.Color.textSecondary
        case .weak: DesignSystem.Color.textStatusError
        case .medium: DesignSystem.Color.textStatusWarning
        case .strong: DesignSystem.Color.textStatusInfo
        }

        let progress = switch strength {
        case .none: 0.0
        case .weak: 0.25
        case .medium: 0.75
        case .strong: 1.0
        }

        return PasswordStrengthInfo(
            title: title,
            description: description,
            color: color,
            progress: progress
        )
    }

    func passwordHint(validation: Validator.Validation) -> String {
        switch validation.hint {
        case .tooShort(let minimumLength): Localization.hwCloudBackupPasswordRuleV2(minimumLength)
        case .keepGoing(let minimumLength): Localization.hwCloudBackupStrengthHintKeepGoingV2(minimumLength)
        case .almostThere: Localization.hwCloudBackupStrengthHintAlmost
        case .addLowercaseLetter: Localization.hwCloudBackupStrengthHintLowercase
        case .addUppercaseLetter: Localization.hwCloudBackupStrengthHintUppercase
        case .addSpecialCharacter: Localization.hwCloudBackupStrengthHintSymbol
        case .addDigit: Localization.hwCloudBackupStrengthHintNumber
        case .allSatisfied: Localization.hwCloudBackupStrengthHintOk
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
            title: Localization.hwCloudBackupCancelSetupTitle,
            message: Localization.hwCloudBackupCancelSetupDescription(MobileBackupConstants.iCloudServiceName),
            primaryButton: .cancel(Text(Localization.hwCloudBackupCancelSetupContinue)),
            secondaryButton: .destructive(
                Text(Localization.hwCloudBackupCancelSetupCancel),
                action: weakify(self, forFunction: MobileOnboardingICloudBackupViewModel.close)
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
    func complete(savedCredential: WebCredentialUtil.SavedCredential?) {
        delegate?.onICloudBackupComplete(savedCredential: savedCredential)
    }

    func close() {
        logScreenClosedAnalytics()
        delegate?.onICloudBackupClose()
    }
}

// MARK: - Analytics

private extension MobileOnboardingICloudBackupViewModel {
    func logSetPasswordScreenAnalytics() {
        Analytics.log(.walletSettingsSetCloudPasswordScreen, contextParams: analyticsContextParams)
    }

    func logConfirmPasswordScreenAnalytics() {
        Analytics.log(.walletSettingsConfirmCloudPasswordScreen, contextParams: analyticsContextParams)
    }

    func logBackupFinishedAnalytics() {
        Analytics.log(
            event: .backupFinished,
            params: [
                .cardsCount: String(0),
                .backupType: Analytics.ParameterValue.backupTypeCloud.rawValue,
            ],
            contextParams: analyticsContextParams
        )
    }

    func logCreationErrorAnalytics(_ error: Error) {
        Analytics.log(
            event: .walletSettingsCloudBackupCreationError,
            params: MobileBackupStatusUtil.errorAnalyticsParams(error),
            contextParams: analyticsContextParams
        )
    }

    func logScreenClosedAnalytics() {
        Analytics.log(.walletSettingsCloudBackupScreenClosed, contextParams: analyticsContextParams)
    }
}

// MARK: - Types

extension MobileOnboardingICloudBackupViewModel {
    enum State: Equatable {
        case setPassword
        case confirmPassword(String)
    }

    struct PasswordStrengthInfo {
        let title: String
        let description: String
        let color: Color
        let progress: Double
    }

    enum PasswordMatching {
        case none
        case matched
        case notMatched

        var description: String? {
            switch self {
            case .none, .matched: nil
            case .notMatched: Localization.hwCloudBackupPasswordsDontMatch
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
