//
//  MobileSocialWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemBackendAuthentication
import TangemFoundation
import TangemMacro
import TangemLocalization
import TangemMobileWalletBackup
import TangemMobileWalletSdk
import TangemSocialAuthentication
import struct TangemSdk.Mnemonic
import struct TangemUIUtils.AlertBinder
import struct TangemUI.TangemSnackbar
import class TangemUI.Toast

final class MobileSocialWalletViewModel: ObservableObject {
    @Published private(set) var state: State = .idle

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    private let supportUserIdentifier = UUID().uuidString
    private let analyticsLogger = MobileSocialLoginAnalyticsLogger()

    private let input: MobileSocialWalletInput
    private let socialAuthProvider: SocialAuthProvider
    private let backupManager: MobileWalletSocialBackupManager

    private weak var coordinator: MobileSocialWalletRoutable?

    init(
        input: MobileSocialWalletInput,
        socialAuthProvider: SocialAuthProvider,
        backupManager: MobileWalletSocialBackupManager,
        coordinator: MobileSocialWalletRoutable
    ) {
        self.input = input
        self.socialAuthProvider = socialAuthProvider
        self.backupManager = backupManager
        self.coordinator = coordinator

        runTask(in: self) { viewModel in
            await viewModel.performFlow()
        }
    }
}

// MARK: - Flow

private extension MobileSocialWalletViewModel {
    func performFlow() async {
        if input.hasBackup {
            await commonFlow(mode: .restore)
        } else {
            await agreementFlow()
        }
    }

    func agreementFlow() async {
        await setupAgreementState()
    }

    func commonFlow(mode: Mode) async {
        do {
            await setupState(mode: mode)

            if let walletBinding = try await existingWalletBinding() {
                await restoreFlow(walletBinding: walletBinding)
            } else {
                await createFlow(mode: mode)
            }

        } catch {
            AppLogger.error("Social wallet flow failed", error: error)
            await closeWithFailure(failure: .somethingWentWrong)
        }
    }

    func createFlow(mode: Mode) async {
        let wallet: CreatedWallet

        do {
            wallet = try await makeWallet()
        } catch {
            AppLogger.error("Social wallet creation failed", error: error)
            await closeWithFailure(failure: .somethingWentWrong)
            return
        }

        let walletId = wallet.userWalletModel.userWalletId

        do {
            try await register(wallet: wallet)
        } catch {
            AppLogger.error("Social wallet register failed", error: error)
            await rollbackWallet(id: walletId, error: error)
            await closeWithFailure(failure: .somethingWentWrong)
            return
        }

        await backupFlow(wallet: wallet, mode: mode)
    }

    func backupFlow(wallet: CreatedWallet, mode: Mode) async {
        do {
            try await createBackup(wallet: wallet)
        } catch {
            AppLogger.error("Social wallet backup failed", error: error)
            await presentBackupRetryAlert(wallet: wallet, mode: mode)
            return
        }

        let walletId = wallet.userWalletModel.userWalletId

        do {
            try store(userWalletModel: wallet.userWalletModel)
            analyticsLogger.logWalletCreated(source: input.source)
            logMarketingConsentIfNeeded(mode: mode)

            await presentWalletCreatedToast()
            await openMain(userWalletModel: wallet.userWalletModel)
        } catch {
            AppLogger.error("Social wallet store failed", error: error)
            cleanMobileWallet(walletId)
            await closeWithFailure(failure: .somethingWentWrong)
        }
    }

    func restoreFlow(walletBinding: SocialAuthWalletBinding) async {
        guard backupManager.isStorageAvailable else {
            AppLogger.error("Social wallet restore failed", error: WalletBackupStorageError.storageUnavailable)
            await presentCloudUnavailableAlert()
            return
        }

        let recoveredBackup: SocialAuthRecoveredBackup

        do {
            recoveredBackup = try await socialAuthProvider.recoverWalletBackup(binding: walletBinding)
        } catch {
            AppLogger.error("Social wallet restore failed", error: error)
            await presentRestoreFailedAlert()
            return
        }

        guard !isWalletAdded(walletId: recoveredBackup.walletId) else {
            AppLogger.error("Social wallet restore failed", error: UserWalletRepositoryError.duplicateWalletAdded)
            await presentWalletAlreadyAddedAlert()
            return
        }

        let userWalletModel: UserWalletModel

        do {
            userWalletModel = try await makeImportedUserWalletModel(mnemonicWords: recoveredBackup.payload.mnemonicWords)
        } catch {
            AppLogger.error("Social wallet restore failed", error: error)
            await presentRestoreFailedAlert()
            return
        }

        let walletId = userWalletModel.userWalletId

        do {
            try await registerRestored(userWalletModel: userWalletModel)
        } catch {
            AppLogger.error("Social wallet restore register failed", error: error)
            cleanMobileWallet(walletId)
            await closeWithFailure(failure: .somethingWentWrong)
            return
        }

        do {
            try store(userWalletModel: userWalletModel)
            analyticsLogger.logWalletRestored(source: input.source)

            await presentWalletAddedToast()
            await openMain(userWalletModel: userWalletModel)
        } catch {
            AppLogger.error("Social wallet restore store failed", error: error)
            cleanMobileWallet(walletId)
            await closeWithFailure(failure: .somethingWentWrong)
        }
    }
}

// MARK: - State

private extension MobileSocialWalletViewModel {
    func setupAgreementState() async {
        let viewModel = makeAgreementViewModel()
        let state = State.agreement(viewModel: viewModel)
        await setup(state: state)
    }

    func setupCreatingState() async {
        let item = ProcessingItem(
            title: Localization.socialLoginCreatingWallet,
            description: Localization.socialLoginCreatingWalletDescription
        )
        let state = State.processing(item: item)
        await setup(state: state)
    }

    func setupRestoringState() async {
        let item = ProcessingItem(
            title: Localization.socialLoginRestoringWallet,
            description: Localization.socialLoginRestoringWalletDescription
        )
        let state = State.processing(item: item)
        await setup(state: state)
    }

    func setupSupportState() async {
        let input = SupportChatInputModel(
            logsComposer: LogsComposer(infoProvider: BaseDataCollector()),
            userIdentifier: supportUserIdentifier,
            source: .socialLogin
        )
        let state = State.support(viewModel: SupportChatViewModel(input: input))
        await setup(state: state)
    }

    func setupState(mode: Mode) async {
        switch mode {
        case .create:
            await setupCreatingState()
        case .restore:
            await setupRestoringState()
        }
    }

    @MainActor
    func setup(state: State) {
        self.state = state
    }
}

// MARK: - Backup handlers

private extension MobileSocialWalletViewModel {
    func onBackupRetry(wallet: CreatedWallet, mode: Mode) {
        runTask(in: self) { viewModel in
            await viewModel.backupFlow(wallet: wallet, mode: mode)
        }
    }

    func onBackupRetryCancel(userWalletId: UserWalletId) {
        runTask(in: self) { viewModel in
            await viewModel.releaseWallet(id: userWalletId)
            await viewModel.close()
        }
    }
}

// MARK: - Alerts

@MainActor
private extension MobileSocialWalletViewModel {
    func presentCloudUnavailableAlert() {
        presentAlert(
            title: Localization.socialLoginErrorCloudAccessTitle,
            message: Localization.socialLoginErrorCloudAccessDescription(MobileBackupConstants.iCloudServiceName)
        )
    }

    func presentRestoreFailedAlert() {
        presentAlert(
            title: Localization.commonSomethingWentWrong,
            message: Localization.socialLoginErrorRestoreFailedDescription
        )
    }

    func presentWalletAlreadyAddedAlert() {
        let message = Localization.userWalletListErrorWalletAlreadySaved
        analyticsLogger.logErrorShown(message: message)

        let alert = AlertBuilder.makeOkGotItAlert(
            message: message,
            okAction: { [weak self] in
                self?.onAlertCancel()
            }
        )

        present(alert: alert)
    }

    func presentBackupRetryAlert(wallet: CreatedWallet, mode: Mode) {
        let message = Localization.socialLoginErrorBackupNotSaved
        analyticsLogger.logErrorShown(message: message)

        let alert = AlertBuilder.makeAlert(
            title: Localization.commonSomethingWentWrong,
            message: message,
            with: .withPrimaryCancelButton(
                cancelAction: { [weak self] in
                    self?.onBackupRetryCancel(userWalletId: wallet.userWalletModel.userWalletId)
                },
                secondaryTitle: Localization.commonRetry,
                secondaryAction: { [weak self] in
                    self?.onBackupRetry(wallet: wallet, mode: mode)
                }
            )
        )

        present(alert: alert)
    }

    func presentAlert(title: String, message: String) {
        analyticsLogger.logErrorShown(message: message)

        let alert = AlertBuilder.makeAlert(
            title: title,
            message: message,
            with: .withPrimaryCancelButton(
                cancelAction: { [weak self] in
                    self?.onAlertCancel()
                },
                secondaryTitle: Localization.socialLoginErrorSupport,
                secondaryAction: { [weak self] in
                    self?.onSupport()
                }
            )
        )

        present(alert: alert)
    }

    func onAlertCancel() {
        close()
    }

    func onSupport() {
        runTask(in: self) { viewModel in
            await viewModel.setupSupportState()
        }
    }

    func present(alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }
}

// MARK: - Toasts

private extension MobileSocialWalletViewModel {
    func presentWalletCreatedToast() async {
        await presentSuccessToast(title: Localization.socialLoginToastWalletCreated)
    }

    func presentWalletAddedToast() async {
        await presentSuccessToast(title: Localization.socialLoginToastWalletAdded)
    }

    @MainActor
    func presentSuccessToast(title: String) {
        let snackbar = TangemSnackbar(title: title)
            .icon(DesignSystem.Icons.Success.filled20)
            .iconColor(DesignSystem.Color.iconAccentBlue)

        Toast(view: snackbar).present(
            layout: .top(padding: Constants.toastTopPadding),
            type: .temporary()
        )
    }
}

// MARK: - Private methods

private extension MobileSocialWalletViewModel {
    func existingWalletBinding() async throws -> SocialAuthWalletBinding? {
        let startDate = Date()

        do {
            let walletBinding = try await socialAuthProvider.existingWalletBinding(credentials: input.credentials)
            await waitForMinimumDuration(since: startDate)
            return walletBinding
        } catch {
            throw error
        }
    }

    func makeWallet() async throws -> CreatedWallet {
        let recoveryKey = try SocialWalletBackupKeyGenerator().makeKey()
        let userWalletModel = try await makeUserWalletModel()

        return CreatedWallet(
            recoveryKey: recoveryKey,
            userWalletModel: userWalletModel
        )
    }

    func createBackup(wallet: CreatedWallet) async throws {
        let walletId = wallet.userWalletModel.userWalletId
        let context = try CommonMobileWalletSdk().validate(auth: .none, for: walletId)

        try await backupManager.createBackup(
            context: context,
            userWalletId: walletId,
            recoveryKey: wallet.recoveryKey
        )
    }

    func register(wallet: CreatedWallet) async throws {
        let encryptedRecoveryKey = try await socialAuthProvider.encryptRecoveryKey(wallet.recoveryKey)

        try await BackendAuthenticationRegistrar.registerNewUnprotectedSocialMobileWallet(
            wallet.userWalletModel,
            recoveryEnrollment: UserWalletRecoveryEnrollment(
                providerIdToken: input.credentials.identityToken,
                encryptedRecoveryKey: encryptedRecoveryKey
            )
        )
    }

    func registerRestored(userWalletModel: UserWalletModel) async throws {
        try await BackendAuthenticationRegistrar.registerNewUnprotectedSocialMobileWallet(
            userWalletModel,
            recoveryEnrollment: nil
        )
    }

    func rollbackWallet(id userWalletId: UserWalletId, error: Error) async {
        if case RegisterUserWalletError.submitFailure = error {
            await releaseWallet(id: userWalletId)
        } else {
            cleanMobileWallet(userWalletId)
        }
    }

    func releaseWallet(id userWalletId: UserWalletId) async {
        await unregisterWallet(id: userWalletId)
        cleanMobileWallet(userWalletId)
    }

    func unregisterWallet(id: UserWalletId) async {
        do {
            try await BackendAuthenticationRegistrar.unregisterSocialMobileWallet(id: id)
        } catch {
            AppLogger.error("Social wallet unregister failed", error: error)
        }
    }

    func cleanMobileWallet(_ userWalletId: UserWalletId) {
        MobileCleanupUtil.cleanMobileWallet(walletId: userWalletId)
    }

    func makeUserWalletModel() async throws -> UserWalletModel {
        try await MobileCreationUtil().makeCreatedModel(hasSocialLogin: true)
    }

    func isWalletAdded(walletId: String) -> Bool {
        userWalletRepository.models.contains { $0.userWalletId.stringValue == walletId }
    }

    func makeImportedUserWalletModel(mnemonicWords: [String]) async throws -> UserWalletModel {
        try await MobileCreationUtil().makeImportedModel(
            mnemonic: Mnemonic(with: mnemonicWords.joined(separator: " ")),
            passphrase: nil,
            hasMnemonicBackup: false,
            hasICloudBackup: false,
            hasSocialLogin: true
        )
    }

    func store(userWalletModel: UserWalletModel) throws {
        AmplitudeWrapper.shared.setUserIdIfOnboarding(userWalletId: userWalletModel.userWalletId)
        try userWalletRepository.add(userWalletModel: userWalletModel)
    }

    func makeAgreementViewModel() -> MobileSocialAgreementViewModel {
        MobileSocialAgreementViewModel(coordinator: self)
    }

    func waitForMinimumDuration(since startDate: Date) async {
        let remainingDuration = Constants.walletBindingMinimumDuration - Date().timeIntervalSince(startDate)

        guard remainingDuration > 0 else {
            return
        }

        try? await Task.sleep(for: .seconds(remainingDuration))
    }

    func logMarketingConsentIfNeeded(mode: Mode) {
        guard case .create(let marketingConsent) = mode else {
            return
        }
        analyticsLogger.logMarketingEmailsConsent(marketingConsent)
    }
}

// MARK: - Navigation

@MainActor
private extension MobileSocialWalletViewModel {
    func openMain(userWalletModel: UserWalletModel) {
        coordinator?.socialWalletOpenMain(userWalletModel: userWalletModel)
    }

    func closeWithFailure(failure: MobileSocialWalletFailure) {
        coordinator?.socialWalletFailed(failure: failure)
        coordinator?.socialWalletClose()
    }

    func close() {
        coordinator?.socialWalletClose()
    }
}

// MARK: - Private types

private extension MobileSocialWalletViewModel {
    enum Mode {
        case create(marketingConsent: MobileSocialMarketingConsent)
        case restore
    }

    struct CreatedWallet {
        let recoveryKey: Data
        let userWalletModel: UserWalletModel
    }

    enum Constants {
        static let toastTopPadding: CGFloat = 8
        static let walletBindingMinimumDuration: TimeInterval = 3
    }
}

// MARK: - MobileSocialAgreementRoutable

extension MobileSocialWalletViewModel: MobileSocialAgreementRoutable {
    func onSocialAgreementClose() {
        close()
    }

    func onSocialAgreementAccept(marketingConsent: MobileSocialMarketingConsent) {
        runTask(in: self) { viewModel in
            await viewModel.commonFlow(mode: .create(marketingConsent: marketingConsent))
        }
    }
}

// MARK: - Types

extension MobileSocialWalletViewModel {
    @RawCaseName
    enum State {
        case idle
        case agreement(viewModel: MobileSocialAgreementViewModel)
        case processing(item: ProcessingItem)
        case support(viewModel: SupportChatViewModel)
    }

    struct ProcessingItem {
        let title: String
        let description: String
    }
}
