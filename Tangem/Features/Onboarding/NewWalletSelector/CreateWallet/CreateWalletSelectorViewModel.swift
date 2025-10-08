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
    @Published var isScanning: Bool = false

    @Published var mailViewModel: MailViewModel?

    @Published var actionSheet: ActionSheetBinder?
    @Published var error: AlertBinder?

    let title = Localization.commonTangemWallet
    let description = Localization.welcomeCreateWalletHardwareDescription
    let scanTitle = Localization.welcomeUnlockCard
    let buyTitle = Localization.detailsBuyWallet
    let otherMethodTitle = Localization.welcomeCreateWalletOtherMethod

    lazy var chipItems: [ChipItem] = makeChipItems()
    lazy var mobileWalletItem: MobileWalletItem = makeMobileWalletItem()

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

    private weak var coordinator: CreateWalletSelectorRoutable?

    init(coordinator: CreateWalletSelectorRoutable) {
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension CreateWalletSelectorViewModel {
    func onAppear() {
        Analytics.log(.onboardingStarted)
    }

    func onScanTap() {
        scanCard()
    }

    func onBuyTap() {
        openBuyHardwareWallet()
    }
}

// MARK: - Private methods

private extension CreateWalletSelectorViewModel {
    func makeChipItems() -> [ChipItem] {
        [
            ChipItem(icon: Assets.Glyphs.checkmarkShield, title: Localization.welcomeCreateWalletFeatureClass),
            ChipItem(icon: Assets.Glyphs.flash, title: Localization.welcomeCreateWalletFeatureDelivery),
            ChipItem(icon: Assets.Glyphs.sparkles, title: Localization.welcomeCreateWalletFeatureUse),
        ]
    }

    func makeMobileWalletItem() -> MobileWalletItem {
        MobileWalletItem(
            title: Localization.welcomeCreateWalletMobileTitle,
            description: Localization.welcomeCreateWalletMobileDescription,
            action: weakify(self, forFunction: CreateWalletSelectorViewModel.onMobileWalletTap)
        )
    }

    func onMobileWalletTap() {
        openCreateMobileWallet()
    }
}

// MARK: - Card operations

private extension CreateWalletSelectorViewModel {
    func scanCard() {
        Analytics.log(Analytics.CardScanSource.createWallet.cardScanButtonEvent)

        isScanning = true

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
                Analytics.log(.cardWasScanned, params: [.source: Analytics.CardScanSource.createWallet.cardWasScannedParameterValue])

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
                Analytics.log(.cardWasScanned, params: [.source: Analytics.CardScanSource.createWallet.cardWasScannedParameterValue])

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

private extension CreateWalletSelectorViewModel {
    func openCreateMobileWallet() {
        Analytics.log(.buttonMobileWallet)

        let input = MobileOnboardingInput(flow: .walletCreate)
        let options = OnboardingCoordinator.Options.mobileInput(input)
        coordinator?.openOnboarding(options: options)
    }

    func openBuyHardwareWallet() {
        Analytics.log(.onboardingButtonBuy, params: [.source: .createWallet])
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
    struct ChipItem: Hashable {
        let icon: ImageType
        let title: String
    }

    struct MobileWalletItem {
        let title: String
        let description: String
        let action: () -> Void
    }
}
