//
//  CreateWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemUIUtils
import TangemAssets
import TangemLocalization

final class CreateWalletSelectorViewModel: ObservableObject {
    @Published var isScanAvailable = false
    @Published var isScanning: Bool = false

    @Published var mailViewModel: MailViewModel?

    @Published var actionSheet: ActionSheetBinder?
    @Published var error: AlertBinder?

    let navigationBarHeight = OnboardingLayoutConstants.navbarSize.height
    let supportButtonTitle = Localization.walletCreateNavInfoTitle
    let screenTitle = Localization.walletCreateTitle

    var walletItems: [WalletItem] = []
    let scanItem: ScanItem

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

    private weak var coordinator: CreateWalletSelectorRoutable?

    init(coordinator: CreateWalletSelectorRoutable) {
        self.coordinator = coordinator
        scanItem = ScanItem(
            title: Localization.walletCreateScanQuestion,
            buttonTitle: Localization.walletCreateScanTitle,
            buttonIcon: Assets.tangemIcon
        )
        walletItems = makeWalletItems()
    }
}

// MARK: - Internal methods

extension CreateWalletSelectorViewModel {
    func onAppear() {
        scheduleScanAvailability()
    }

    func onSupportTap() {
        openWhatToChoose()
    }

    func onScanTap() {
        scanCard()
    }
}

// MARK: - Private methods

private extension CreateWalletSelectorViewModel {
    func makeWalletItems() -> [WalletItem] {
        [
            WalletItem(
                title: Localization.walletCreateMobileTitle,
                infoTag: InfoTag(text: Localization.commonFree, style: .secondary),
                description: Localization.walletCreateMobileDescription,
                action: weakify(self, forFunction: CreateWalletSelectorViewModel.openMobileWallet)
            ),
            WalletItem(
                title: Localization.walletCreateHardwareTitle,
                infoTag: InfoTag(text: Localization.walletCreateHardwareBadge("$54.90"), style: .accent),
                description: Localization.walletCreateHardwareDescription,
                action: weakify(self, forFunction: CreateWalletSelectorViewModel.openHardwareWallet)
            ),
        ]
    }

    func scheduleScanAvailability() {
        guard !isScanAvailable else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.isScanAvailable = true
        }
    }
}

// MARK: - Card operations

private extension CreateWalletSelectorViewModel {
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
                    viewModel.openOnboarding(options: .input(input))
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
                        viewModel.openMain(userWalletModel: userWalletModel)
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

private extension CreateWalletSelectorViewModel {
    func openMobileWallet() {
        let input = HotOnboardingInput(flow: .walletCreate)
        let options = OnboardingCoordinator.Options.hotInput(input)
        coordinator?.openOnboarding(options: options)
    }

    func openHardwareWallet() {
        safariManager.openURL(TangemBlogUrlBuilder().url(root: .pricing))
    }

    func openWhatToChoose() {
        // [REDACTED_TODO_COMMENT]
    }

    func openOnboarding(options: OnboardingCoordinator.Options) {
        coordinator?.openOnboarding(options: options)
    }

    func openMain(userWalletModel: UserWalletModel) {
        coordinator?.openMain(userWalletModel: userWalletModel)
    }

    func openTroubleshooting() {
        let sheet = ActionSheet(
            title: Text(Localization.alertTroubleshootingScanCardTitle),
            message: Text(Localization.alertTroubleshootingScanCardMessage),
            buttons: [
                .default(
                    Text(Localization.alertButtonTryAgain),
                    action: weakify(self, forFunction: CreateWalletSelectorViewModel.scanCardTryAgain)
                ),
                .default(
                    Text(Localization.commonReadMore),
                    action: weakify(self, forFunction: CreateWalletSelectorViewModel.openScanCardManual)
                ),
                .default(
                    Text(Localization.alertButtonRequestSupport),
                    action: weakify(self, forFunction: CreateWalletSelectorViewModel.requestSupport)
                ),
                .cancel(),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
    }
}

// MARK: - Helpers

private extension CreateWalletSelectorViewModel {
    func scanCardTryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .introduction])
        scanCard()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .introduction])
        failedCardScanTracker.resetCounter()
        openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient)
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }
}

// MARK: - Types

extension CreateWalletSelectorViewModel {
    struct WalletItem {
        let title: String
        let infoTag: InfoTag
        let description: String
        let action: () -> Void
    }

    struct InfoTag {
        let text: String
        let style: InfoTagStyle
    }

    enum InfoTagStyle {
        case secondary
        case accent

        var color: Color {
            switch self {
            case .secondary:
                Colors.Text.secondary
            case .accent:
                Colors.Text.accent
            }
        }

        var bgColor: Color {
            switch self {
            case .secondary:
                Colors.Control.unchecked
            case .accent:
                Colors.Text.accent.opacity(0.1)
            }
        }
    }

    struct ScanItem {
        let title: String
        let buttonTitle: String
        let buttonIcon: ImageType
    }
}
