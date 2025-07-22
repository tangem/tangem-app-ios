//
//  CreateWalletSelectorCoordinator.swift
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

class CreateWalletSelectorCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var createViewModel: CreateWalletSelectorViewModel?
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
        createViewModel = CreateWalletSelectorViewModel(
            coordinator: self,
            delegate: self
        )
    }
}

// MARK: - CreateNewWalletSelectorRoutable

extension CreateWalletSelectorCoordinator: CreateWalletSelectorRoutable {
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

extension CreateWalletSelectorCoordinator: CreateWalletSelectorDelegate {
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

// MARK: - Navigation

private extension CreateWalletSelectorCoordinator {
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
                .default(
                    Text(Localization.alertButtonTryAgain),
                    action: weakify(self, forFunction: CreateWalletSelectorCoordinator.tryAgain)
                ),
                .default(
                    Text(Localization.commonReadMore),
                    action: weakify(self, forFunction: CreateWalletSelectorCoordinator.openScanCardManual)
                ),
                .default(
                    Text(Localization.alertButtonRequestSupport),
                    action: weakify(self, forFunction: CreateWalletSelectorCoordinator.requestSupport)
                ),
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

private extension CreateWalletSelectorCoordinator {
    func unlockDidFinish(with result: UserWalletRepositoryResult?) {
        if result?.isSuccess != true {
            incomingActionManager.discardIncomingAction()
        }

        switch result {
        case .troubleshooting:
            Analytics.log(.cantScanTheCard, params: [.source: .introduction])
            openTroubleshooting()
        case .onboarding(let input):
            openOnboarding(with: .input(input))
        case .error(let error):
            if error.isCancellationError {
                return
            }

            Analytics.logScanError(error, source: .introduction)
            Analytics.logVisaCardScanErrorIfNeeded(error, source: .introduction)
            self.error = error.alertBinder
        case .success(let model), .partial(let model, _): // partial unlock is impossible in this case
            openMain(with: model)
        case .none:
            return
        }
    }

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

extension CreateWalletSelectorCoordinator {
    struct InputOptions {}

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
