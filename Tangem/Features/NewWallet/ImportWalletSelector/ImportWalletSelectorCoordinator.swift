//
//  ImportWalletSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemUIUtils

class ImportWalletSelectorCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

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
        importViewModel = ImportWalletSelectorViewModel(
            coordinator: self,
            delegate: self
        )
    }
}

// MARK: - ImportWalletSelectorRoutable

extension ImportWalletSelectorCoordinator: ImportWalletSelectorRoutable {
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

extension ImportWalletSelectorCoordinator: ImportWalletSelectorDelegate {
    func scanCard() {
        isScanning = true
        Analytics.beginLoggingCardScan(source: .welcome)

        runTask(in: self) { viewModel in
            let cardScanner = CardScannerFactory().makeDefaultScanner()
            let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)

            let result = await userWalletCardScanner.scanCard()
            await runOnMain {
                viewModel.unlockDidFinish(with: result)
            }
        }
    }
}

// MARK: - Navigation

private extension ImportWalletSelectorCoordinator {
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
                    action: weakify(self, forFunction: ImportWalletSelectorCoordinator.tryAgain)
                ),
                .default(
                    Text(Localization.commonReadMore),
                    action: weakify(self, forFunction: ImportWalletSelectorCoordinator.openScanCardManual)
                ),
                .default(
                    Text(Localization.alertButtonRequestSupport),
                    action: weakify(self, forFunction: ImportWalletSelectorCoordinator.requestSupport)
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

private extension ImportWalletSelectorCoordinator {
    func unlockDidFinish(with result: UserWalletCardScanner.Result) {
        isScanning = false

        switch result {
        case .scanTroubleshooting:
            Analytics.log(.cantScanTheCard, params: [.source: .introduction])
            incomingActionManager.discardIncomingAction()
            openTroubleshooting()

        case .onboarding(let input):
            incomingActionManager.discardIncomingAction()
            openOnboarding(with: .input(input))

        case .error(let error) where error.isCancellationError:
            incomingActionManager.discardIncomingAction()

        case .error(let error):
            Analytics.logScanError(error, source: .introduction)
            Analytics.logVisaCardScanErrorIfNeeded(error, source: .introduction)
            incomingActionManager.discardIncomingAction()
            self.error = error.alertBinder

        case .success(let cardInfo):
            do {
                let userWalletModel = try userWalletRepository.unlock(with: .card(cardInfo))
                openMain(with: userWalletModel)
            } catch {
                incomingActionManager.discardIncomingAction()
                self.error = error.alertBinder
            }
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

extension ImportWalletSelectorCoordinator {
    struct InputOptions {}

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
