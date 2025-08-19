//
//  ImportWalletSelectorViewModel.swift
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

final class ImportWalletSelectorViewModel: ObservableObject {
    @Published var isBuyAvailable = false
    @Published var isScanning: Bool = false

    @Published var mailViewModel: MailViewModel?

    @Published var actionSheet: ActionSheetBinder?
    @Published var error: AlertBinder?

    let navigationBarTitle = Localization.homeButtonAddExistingWallet
    let screenTitle = Localization.walletImportTitle

    var walletItems: [WalletItem] = []
    let buyItem: BuyItem

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

    private weak var coordinator: ImportWalletSelectorRoutable?

    init(coordinator: ImportWalletSelectorRoutable) {
        self.coordinator = coordinator
        buyItem = BuyItem(
            title: Localization.walletImportBuyQuestion,
            buttonTitle: Localization.walletImportBuyTitle
        )
        walletItems = makeWalletItems()
    }
}

// MARK: - Internal methods

extension ImportWalletSelectorViewModel {
    func onAppear() {
        scheduleBuyAvailability()
    }

    func onBuyTap() {
        openBuyCard()
    }
}

// MARK: - Private methods

private extension ImportWalletSelectorViewModel {
    func makeWalletItems() -> [WalletItem] {
        [
            WalletItem(
                title: Localization.walletImportSeedTitle,
                titleIcon: nil,
                infoTag: nil,
                description: Localization.walletImportSeedDescription,
                isEnabled: true,
                action: weakify(self, forFunction: ImportWalletSelectorViewModel.openImportSeedPhrase)
            ),
            WalletItem(
                title: Localization.walletImportScanTitle,
                titleIcon: Assets.tangemIcon,
                infoTag: nil,
                description: Localization.walletImportScanDescription,
                isEnabled: true,
                action: weakify(self, forFunction: ImportWalletSelectorViewModel.scanCard)
            ),
            WalletItem(
                title: Localization.walletImportIcloudTitle,
                titleIcon: nil,
                infoTag: InfoTag(text: Localization.commonComingSoon, style: .secondary),
                description: Localization.walletImportIcloudDescription,
                isEnabled: false,
                action: {}
            ),
        ]
    }

    func scheduleBuyAvailability() {
        guard !isBuyAvailable else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.isBuyAvailable = true
        }
    }
}

// MARK: - Card operations

private extension ImportWalletSelectorViewModel {
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

            case .onboarding(let input, _):
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
                    if let newUserWalletModel = CommonUserWalletModelFactory().makeModel(
                        walletInfo: .cardWallet(cardInfo),
                        keys: .cardWallet(keys: cardInfo.card.wallets)
                    ) {
                        try viewModel.userWalletRepository.add(userWalletModel: newUserWalletModel)

                        await runOnMain {
                            viewModel.isScanning = false
                            viewModel.openMain(userWalletModel: newUserWalletModel)
                        }
                    } else {
                        throw UserWalletRepositoryError.cantUnlockWallet
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

private extension ImportWalletSelectorViewModel {
    func openImportSeedPhrase() {
        let input = HotOnboardingInput(flow: .walletImport)
        let options = OnboardingCoordinator.Options.hotInput(input)
        coordinator?.openOnboarding(options: options)
    }

    func openBuyCard() {
        safariManager.openURL(TangemBlogUrlBuilder().url(root: .pricing))
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
                    action: weakify(self, forFunction: ImportWalletSelectorViewModel.scanCardTryAgain)
                ),
                .default(
                    Text(Localization.commonReadMore),
                    action: weakify(self, forFunction: ImportWalletSelectorViewModel.openScanCardManual)
                ),
                .default(
                    Text(Localization.alertButtonRequestSupport),
                    action: weakify(self, forFunction: ImportWalletSelectorViewModel.requestSupport)
                ),
                .cancel(),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
    }
}

// MARK: - Helpers

private extension ImportWalletSelectorViewModel {
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

extension ImportWalletSelectorViewModel {
    struct WalletItem: Identifiable {
        let id = UUID()
        let title: String
        let titleIcon: ImageType?
        let infoTag: InfoTag?
        let description: String
        let isEnabled: Bool
        let action: () -> Void
    }

    struct InfoTag {
        let text: String
        let style: InfoTagStyle
    }

    enum InfoTagStyle {
        case secondary

        var color: Color {
            switch self {
            case .secondary:
                Colors.Text.secondary
            }
        }

        var bgColor: Color {
            switch self {
            case .secondary:
                Colors.Control.unchecked
            }
        }
    }

    struct BuyItem {
        let title: String
        let buttonTitle: String
    }
}
