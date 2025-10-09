//
//  HardwareCreateWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemUIUtils
import TangemLocalization
import TangemAssets

final class HardwareCreateWalletViewModel: ObservableObject {
    @Published var isScanning: Bool = false

    @Published var actionSheet: ActionSheetBinder?
    @Published var alert: AlertBinder?

    let screenTitle = "Create Tangem Wallet"
    let buyButtonTitle = Localization.detailsBuyWallet
    let scanButtonTitle = Localization.homeButtonScan

    lazy var infoItems: [InfoItem] = makeInfoItems()

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

    private weak var coordinator: HardwareCreateWalletRoutable?

    init(coordinator: HardwareCreateWalletRoutable) {
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension HardwareCreateWalletViewModel {
    func onScanTap() {
        scanCard()
    }

    func onBuyTap() {
        openBuyCard()
    }
}

// MARK: - Private methods

extension HardwareCreateWalletViewModel {
    func makeInfoItems() -> [InfoItem] {
        let keyTrait = InfoItem(
            icon: Assets.Glyphs.mobileSecurity,
            title: Localization.hwUpgradeKeyMigrationTitle,
            subtitle: Localization.hwUpgradeKeyMigrationDescription
        )

        let fundsTrait = InfoItem(
            icon: Assets.Visa.securityCheck,
            title: Localization.hwUpgradeFundsAccessTitle,
            subtitle: Localization.hwUpgradeFundsAccessDescription
        )

        let securityTrait = InfoItem(
            icon: Assets.lock24,
            title: Localization.hwUpgradeGeneralSecurityTitle,
            subtitle: Localization.hwUpgradeGeneralSecurityDescription
        )

        return [keyTrait, fundsTrait, securityTrait]
    }
}

// MARK: - Card operations

private extension HardwareCreateWalletViewModel {
    func scanCard() {
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
                    viewModel.alert = error.alertBinder
                }

            case .onboarding(let input, _):
                Analytics.log(.cardWasScanned, params: [.source: Analytics.CardScanSource.createWallet.cardWasScannedParameterValue])

                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.openOnboarding(input: input)
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
                        viewModel.alert = error.alertBinder
                    }
                }
            }
        }
    }
}

// MARK: - Navigation

private extension HardwareCreateWalletViewModel {
    func openOnboarding(input: OnboardingInput) {
        coordinator?.openOnboarding(input: input)
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
                    action: weakify(self, forFunction: HardwareCreateWalletViewModel.scanCardTryAgain)
                ),
                .default(
                    Text(Localization.commonReadMore),
                    action: weakify(self, forFunction: HardwareCreateWalletViewModel.openScanCardManual)
                ),
                .default(
                    Text(Localization.alertButtonRequestSupport),
                    action: weakify(self, forFunction: HardwareCreateWalletViewModel.requestSupport)
                ),
                .cancel(),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func openBuyCard() {
        safariManager.openURL(TangemBlogUrlBuilder().url(root: .pricing))
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }

    func openMail() {
        coordinator?.openMail(dataCollector: BaseDataCollector(), recipient: EmailConfig.default.recipient)
    }
}

// MARK: - Helpers

private extension HardwareCreateWalletViewModel {
    func scanCardTryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .introduction])
        scanCard()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .introduction])
        failedCardScanTracker.resetCounter()
        openMail()
    }
}

// MARK: - Types

extension HardwareCreateWalletViewModel {
    struct InfoItem: Identifiable {
        let id = UUID()
        let icon: ImageType
        let title: String
        let subtitle: String
    }
}
