//
//  WelcomeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk
import TangemFoundation
import TangemUIUtils
import TangemLocalization

class WelcomeViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    @Published var error: AlertBinder?
    @Published var actionSheet: ActionSheetBinder?

    let storiesModel: StoriesViewModel

    let isScanningCard: CurrentValueSubject<Bool, Never> = .init(false)

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

    func onAppear() {
        Analytics.log(.introductionProcessOpened)
        incomingActionManager.becomeFirstResponder(self)
    }

    func onDisappear() {
        incomingActionManager.resignFirstResponder(self)
    }

    func scanCard() {
        isScanningCard.send(true)
        Analytics.beginLoggingCardScan(source: .welcome)

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
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanningCard.send(false)
                    viewModel.error = error.alertBinder
                }

            case .onboarding(let input):
                viewModel.incomingActionManager.discardIncomingAction()

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
                do {
                    let userWalletModel = try viewModel.userWalletRepository.unlock(with: .card(cardInfo))

                    await runOnMain {
                        viewModel.isScanningCard.send(false)
                        viewModel.openMain(with: userWalletModel)
                    }

                } catch {
                    viewModel.incomingActionManager.discardIncomingAction()

                    await runOnMain {
                        viewModel.isScanningCard.send(false)
                        viewModel.error = error.alertBinder
                    }
                }
            }
        }
    }
}

// MARK: - Navigation

extension WelcomeViewModel {
    func openTroubleshooting() {
        let sheet = ActionSheet(
            title: Text(Localization.alertTroubleshootingScanCardTitle),
            message: Text(Localization.alertTroubleshootingScanCardMessage),
            buttons: [
                .default(Text(Localization.alertButtonTryAgain), action: weakify(self, forFunction: WelcomeViewModel.tryAgain)),
                .default(Text(Localization.commonReadMore), action: weakify(self, forFunction: WelcomeViewModel.openScanCardManual)),
                .default(Text(Localization.alertButtonRequestSupport), action: weakify(self, forFunction: WelcomeViewModel.requestSupport)),
                .cancel(),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
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
        coordinator?.openNewWalletSelector(with: .create)
    }

    func importWallet() {
        coordinator?.openNewWalletSelector(with: .import)
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
