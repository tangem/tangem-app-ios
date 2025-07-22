//
//  NewWalletSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemLocalization
import TangemFoundation
import TangemUIUtils

class NewWalletSelectorCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var createViewModel: CreateWalletSelectorViewModel?
    @Published private(set) var importViewModel: ImportWalletSelectorViewModel?
    @Published var mailViewModel: MailViewModel?
    @Published var isScanning: Bool = false

    @Published var onboardingCoordinator: OnboardingCoordinator?

    @Published var actionSheet: ActionSheetBinder?
    @Published var error: AlertBinder?

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.safariManager) private var safariManager: SafariManager

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: InputOptions) {
        switch options.input {
        case .create:
            createViewModel = CreateWalletSelectorViewModel(
                coordinator: self,
                delegate: self
            )
        case .import:
            importViewModel = ImportWalletSelectorViewModel(
                coordinator: self,
                delegate: self
            )
        }
    }
}

// MARK: - CreateNewWalletSelectorRoutable

extension NewWalletSelectorCoordinator: CreateWalletSelectorRoutable {
    func openMobileWallet() {
        let input = HotOnboardingInput(flow: .walletCreate)
        let options = OnboardingCoordinator.Options.hotInput(input)
        openOnboarding(with: options)
    }

    func openHardwareWallet() {
        openCardPricing()
    }

    func openWhatToChoose() {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - CreateWalletSelectorDelegate

extension NewWalletSelectorCoordinator: CreateWalletSelectorDelegate {
    func scanCard() {
        isScanning = true
        Analytics.beginLoggingCardScan(source: .welcome)

        runTask(in: self) { viewModel in
            let cardScanner = CardScannerFactory().makeDefaultScanner()
            let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)
            let result = await userWalletCardScanner.scanCard()

            switch result {
            case .error(let error) where error.isCancellationError:
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                }

            case .error(let error):
                Analytics.logScanError(error, source: .introduction)
                Analytics.logVisaCardScanErrorIfNeeded(error, source: .introduction)
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.error = error.alertBinder
                }

            case .onboarding(let input):
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.openOnboarding(with: .input(input))
                }

            case .scanTroubleshooting:
                Analytics.log(.cantScanTheCard, params: [.source: .introduction])
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.openTroubleshooting()
                }

            case .success(let cardInfo):
                do {
                    let userWalletModel = try viewModel.userWalletRepository.unlock(with: .card(cardInfo))

                    await runOnMain {
                        viewModel.isScanning = false
                        viewModel.openMain(with: userWalletModel)
                    }

                } catch {
                    viewModel.incomingActionManager.discardIncomingAction()

                    await runOnMain {
                        viewModel.isScanning = false
                        viewModel.error = error.alertBinder
                    }
                }
            }
        }
    }
}

// MARK: - ImportWalletSelectorRoutable

extension NewWalletSelectorCoordinator: ImportWalletSelectorRoutable {
    func openOnboarding() {
        let input = HotOnboardingInput(flow: .walletImport)
        let options = OnboardingCoordinator.Options.hotInput(input)
        openOnboarding(with: options)
    }

    func openBuyCard() {
        openCardPricing()
    }
}

// MARK: - ImportWalletSelectorDelegate

extension NewWalletSelectorCoordinator: ImportWalletSelectorDelegate {}

// MARK: - Navigation

private extension NewWalletSelectorCoordinator {
    func openOnboarding(with inputOptions: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(with: userWalletModel)
            case .dismiss:
                self?.onboardingCoordinator = nil
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        onboardingCoordinator = coordinator
    }

    func openTroubleshooting() {
        let sheet = ActionSheet(
            title: Text(Localization.alertTroubleshootingScanCardTitle),
            message: Text(Localization.alertTroubleshootingScanCardMessage),
            buttons: [
                .default(Text(Localization.alertButtonTryAgain), action: weakify(self, forFunction: NewWalletSelectorCoordinator.tryAgain)),
                .default(Text(Localization.commonReadMore), action: weakify(self, forFunction: NewWalletSelectorCoordinator.openScanCardManual)),
                .default(Text(Localization.alertButtonRequestSupport), action: weakify(self, forFunction: NewWalletSelectorCoordinator.requestSupport)),
                .cancel(),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func openMain(with userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)
    }

    func openCardPricing() {
        safariManager.openURL(TangemBlogUrlBuilder().url(root: .pricing))
    }
}

// MARK: - Private methods

private extension NewWalletSelectorCoordinator {
    func tryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .introduction])
        scanCard()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .introduction])
        failedCardScanTracker.resetCounter()
        openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient)
    }
}

// MARK: - Options

extension NewWalletSelectorCoordinator {
    struct InputOptions {
        let input: NewWalletSelectorInput
    }

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
