//
//  AuthViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import TangemLocalization
import TangemFoundation
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ConfirmationDialogViewModel

final class AuthViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?
    @Published var confirmationDialog: ConfirmationDialogViewModel?

    var unlockWithBiometryButtonTitle: String {
        Localization.welcomeUnlock(BiometricAuthorizationUtils.biometryType.name)
    }

    // MARK: - Dependencies

    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private let signInAnalyticsLogger = SignInAnalyticsLogger()

    private weak var coordinator: AuthRoutable?

    private var unlockOnAppear: Bool

    init(unlockOnAppear: Bool = false, coordinator: AuthRoutable) {
        self.unlockOnAppear = unlockOnAppear
        self.coordinator = coordinator
    }

    func tryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .signIn])
        unlockWithCard()
    }

    @MainActor
    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .signIn])
        coordinator?.openScanCardManual()
    }

    @MainActor
    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .signIn])
        failedCardScanTracker.resetCounter()
        openMail()
    }

    func onAppear() {
        Analytics.log(.signInScreenOpened)
        incomingActionManager.becomeFirstResponder(self)

        if unlockOnAppear {
            DispatchQueue.main.async {
                self.unlockOnAppear = false
                self.unlockWithBiometry()
            }
        }
    }

    func onDisappear() {
        incomingActionManager.resignFirstResponder(self)
    }

    func unlockWithBiometryButtonTapped() {
        Analytics.log(.buttonBiometricSignIn)
        unlockWithBiometry()
    }

    func unlockWithBiometry() {
        runTask(in: self) { viewModel in
            do {
                let context = try await UserWalletBiometricsUnlocker().unlock()
                let userWalletModel = try await viewModel.userWalletRepository.unlock(with: .biometrics(context))
                viewModel.signInAnalyticsLogger.logSignInEvent(signInType: .biometrics, userWalletModel: userWalletModel)
                await MainActor.run {
                    viewModel.openMain(with: userWalletModel)
                }
            } catch where error.isCancellationError {
                viewModel.incomingActionManager.discardIncomingAction()
            } catch {
                Analytics.logScanError(error, source: .signIn)
                Analytics.logVisaCardScanErrorIfNeeded(error, source: .signIn)
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.error = error.alertBinder
                }
            }
        }
    }

    func unlockWithCard() {
        isScanningCard = true

        Analytics.log(Analytics.CardScanSource.auth.cardScanButtonEvent)

        runTask(in: self) { viewModel in
            let cardScanner = CardScannerFactory().makeDefaultScanner()
            let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)
            let result = await userWalletCardScanner.scanCard()

            switch result {
            case .error(let error) where error.isCancellationError:
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanningCard = false
                }

            case .error(let error):
                Analytics.logScanError(error, source: .signIn)
                Analytics.logVisaCardScanErrorIfNeeded(error, source: .signIn)
                await viewModel.handleScanError(error)

            case .onboarding(let input, _):
                Analytics.log(
                    .cardWasScanned,
                    params: [.source: Analytics.CardScanSource.auth.cardWasScannedParameterValue],
                    contextParams: input.cardInput.getContextParams()
                )
                viewModel.incomingActionManager.discardIncomingAction()

                await MainActor.run {
                    viewModel.isScanningCard = false
                    viewModel.openOnboarding(with: input)
                }

            case .scanTroubleshooting:
                Analytics.log(.cantScanTheCard, params: [.source: .signIn])
                viewModel.incomingActionManager.discardIncomingAction()

                await MainActor.run {
                    viewModel.isScanningCard = false
                    viewModel.openTroubleshooting()
                }

            case .success(let cardInfo):
                Analytics.log(
                    .cardWasScanned,
                    params: [.source: Analytics.CardScanSource.auth.cardWasScannedParameterValue],
                    contextParams: .custom(cardInfo.analyticsContextData)
                )

                let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

                do {
                    guard let userWalletId = UserWalletId(config: config),
                          let encryptionKey = UserWalletEncryptionKey(config: config) else {
                        throw UserWalletRepositoryError.cantUnlockWallet
                    }

                    let userWalletModel = try await viewModel.userWalletRepository.unlock(
                        with: .encryptionKey(userWalletId: userWalletId, encryptionKey: encryptionKey)
                    )

                    viewModel.signInAnalyticsLogger.logSignInEvent(signInType: .card, userWalletModel: userWalletModel)

                    await MainActor.run {
                        viewModel.isScanningCard = false
                        viewModel.openMain(with: userWalletModel)
                    }

                } catch UserWalletRepositoryError.notFound {
                    // new card scanned, add it
                    await viewModel.handleNotFound(cardInfo: cardInfo)
                } catch {
                    await viewModel.handleScanError(error)
                }
            }
        }
    }

    private func handleNotFound(cardInfo: CardInfo) async {
        do {
            if let newUserWalletModel = CommonUserWalletModelFactory().makeModel(
                walletInfo: .cardWallet(cardInfo),
                keys: .cardWallet(keys: cardInfo.card.wallets)
            ) {
                try userWalletRepository.add(userWalletModel: newUserWalletModel)
                signInAnalyticsLogger.logSignInEvent(signInType: .card, userWalletModel: newUserWalletModel)
                await MainActor.run {
                    isScanningCard = false
                    openMain(with: newUserWalletModel)
                }
            } else {
                throw UserWalletRepositoryError.cantUnlockWallet
            }
        } catch {
            await handleScanError(error)
        }
    }

    private func handleScanError(_ error: Error) async {
        incomingActionManager.discardIncomingAction()

        await runOnMain {
            isScanningCard = false
            self.error = error.alertBinder
        }
    }
}

// MARK: - Navigation

@MainActor
extension AuthViewModel {
    func openTroubleshooting() {
        let tryAgainButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonTryAgain) { [weak self] in
            self?.tryAgain()
        }

        let readMoreButton = ConfirmationDialogViewModel.Button(title: Localization.commonReadMore) { [weak self] in
            self?.openScanCardManual()
        }

        let requestSupportButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonRequestSupport) { [weak self] in
            self?.requestSupport()
        }

        confirmationDialog = ConfirmationDialogViewModel(
            title: Localization.alertTroubleshootingScanCardTitle,
            subtitle: Localization.alertTroubleshootingScanCardMessage,
            buttons: [
                tryAgainButton,
                readMoreButton,
                requestSupportButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
    }

    func openMail() {
        coordinator?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient)
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboarding(with: input)
    }

    func openMain(with model: UserWalletModel) {
        coordinator?.openMain(with: model)
    }
}

// MARK: - IncomingActionResponder

extension AuthViewModel: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        switch action {
        case .start:
            return true
        default:
            return false
        }
    }
}
