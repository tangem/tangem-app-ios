//
//  WelcomeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk
import TangemFoundation
import TangemUIUtils
import TangemLocalization

final class WelcomeViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    @Published var error: AlertBinder?
    @Published var confirmationDialog: ConfirmationDialogViewModel?

    let storiesModel: StoriesViewModel

    let isScanningCard: CurrentValueSubject<Bool, Never> = .init(false)
    private let signInAnalyticsLogger = SignInAnalyticsLogger()

    private weak var coordinator: WelcomeRoutable?

    init(coordinator: WelcomeRoutable, storiesModel: StoriesViewModel) {
        self.coordinator = coordinator
        self.storiesModel = storiesModel
    }

    deinit {
        AppLogger.debug(self)
    }

    func scanCardTapped() {
        scanCard()
    }

    func tryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .introduction])
        scanCard()
    }

    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .introduction])
        coordinator?.openScanCardManual()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .introduction])
        failedCardScanTracker.resetCounter()
        openMail()
    }

    func orderCard() {
        // For some reason the button can be tapped even after we've this flag to FALSE to disable it
        guard !isScanningCard.value else { return }

        openShop()
        Analytics.log(.buttonBuyCards)
    }

    func onFirstAppear() {
        Analytics.log(.introductionProcessOpened)
    }

    func onAppear() {
        incomingActionManager.becomeFirstResponder(self)
    }

    func onDisappear() {
        incomingActionManager.resignFirstResponder(self)
    }

    func scanCard() {
        isScanningCard.send(true)
        Analytics.log(Analytics.CardScanSource.welcome.cardScanButtonEvent)

        runTask(in: self) { viewModel in
            let cardScanner = CardScannerFactory().makeDefaultScanner()
            let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)
            let result = await userWalletCardScanner.scanCard()

            switch result {
            case .error(let error) where error.isCancellationError:
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanningCard.send(false)
                }

            case .error(let error):
                Analytics.logScanError(error, source: .introduction)
                Analytics.logVisaCardScanErrorIfNeeded(error, source: .introduction)
                await viewModel.handleError(error)

            case .onboarding(let input, _):
                Analytics.log(
                    .cardWasScanned,
                    params: [.source: Analytics.CardScanSource.welcome.cardWasScannedParameterValue],
                    contextParams: input.cardInput.getContextParams()
                )
                viewModel.incomingActionManager.discardIncomingAction(if: { !$0.isPromoDeeplink })

                await runOnMain {
                    viewModel.isScanningCard.send(false)
                    viewModel.openOnboarding(with: input)
                }

            case .scanTroubleshooting:
                Analytics.log(.cantScanTheCard, params: [.source: .introduction])
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanningCard.send(false)
                    viewModel.openTroubleshooting()
                }

            case .success(let cardInfo):
                Analytics.log(
                    .cardWasScanned,
                    params: [.source: Analytics.CardScanSource.welcome.cardWasScannedParameterValue],
                    contextParams: .custom(cardInfo.analyticsContextData)
                )

                let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

                do {
                    guard let userWalletId = UserWalletId(config: config),
                          let encryptionKey = UserWalletEncryptionKey(config: config) else {
                        throw UserWalletRepositoryError.cantUnlockWallet
                    }

                    let unlockMethod = UserWalletRepositoryUnlockMethod.encryptionKey(userWalletId: userWalletId, encryptionKey: encryptionKey)
                    let userWalletModel = try await viewModel.userWalletRepository.unlock(with: unlockMethod)
                    viewModel.signInAnalyticsLogger.logSignInEvent(signInType: .card, userWalletModel: userWalletModel)
                    await runOnMain {
                        viewModel.isScanningCard.send(false)
                        viewModel.openMain(with: userWalletModel)
                    }

                } catch UserWalletRepositoryError.notFound {
                    // new card scanned, add it
                    await viewModel.handleNotFound(cardInfo: cardInfo)
                } catch {
                    await viewModel.handleError(error)
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
                await runOnMain {
                    isScanningCard.send(false)
                    openMain(with: newUserWalletModel)
                }
            } else {
                throw UserWalletRepositoryError.cantUnlockWallet
            }
        } catch {
            await handleError(error)
        }
    }

    private func handleError(_ error: Error) async {
        incomingActionManager.discardIncomingAction()

        await runOnMain {
            isScanningCard.send(false)
            self.error = error.alertBinder
        }
    }
}

// MARK: - Navigation

extension WelcomeViewModel {
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

    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboarding(with: input)
    }

    func openMain(with userWalletModel: UserWalletModel) {
        coordinator?.openMain(with: userWalletModel)
    }
}

// MARK: - StoriesDelegate

extension WelcomeViewModel: StoriesDelegate {
    var isScanning: AnyPublisher<Bool, Never> {
        isScanningCard.eraseToAnyPublisher()
    }

    func createWallet() {
        Analytics.log(.introductionProcessButtonCreateNewWallet)
        coordinator?.openCreateWallet()
    }

    func openTokenList() {
        // For some reason the button can be tapped even after we've this flag to FALSE to disable it
        guard !isScanningCard.value else { return }

        Analytics.log(.buttonTokensList)
        coordinator?.openTokensList()
    }

    func openMail() {
        coordinator?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient)
    }

    func openPromotion() {
        Analytics.log(.introductionProcessLearn)
        coordinator?.openPromotion()
    }

    func openShop() {
        coordinator?.openShop()
    }
}

// MARK: - IncomingActionResponder

extension WelcomeViewModel: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        switch action {
        case .start:
            return true
        default:
            return false
        }
    }
}
