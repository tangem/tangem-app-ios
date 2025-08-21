//
//  MobileUpgradeViewModel.swift
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

final class MobileUpgradeViewModel: ObservableObject {
    @Published var isScanning: Bool = false

    @Published var actionSheet: ActionSheetBinder?
    @Published var alert: AlertBinder?

    lazy var info = makeInfo()

    let buyButtonTitle = Localization.detailsBuyWallet
    let scanButtonTitle = Localization.hwUpgradeScanDevice

    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

    private weak var coordinator: MobileUpgradeRoutable?

    init(coordinator: MobileUpgradeRoutable) {
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension MobileUpgradeViewModel {
    func onScanTap() {
        scanCard()
    }

    func onBuyTap() {
        openBuyCard()
    }

    func onCloseTap() {
        close()
    }
}

// MARK: - Private methods

extension MobileUpgradeViewModel {
    func makeInfo() -> InfoItem {
        let keyTrait = TraitItem(
            icon: Assets.Glyphs.mobileSecurity,
            title: Localization.hwUpgradeKeyMigrationTitle,
            subtitle: Localization.hwUpgradeKeyMigrationDescription
        )

        let fundsTrait = TraitItem(
            icon: Assets.Visa.securityCheck,
            title: Localization.hwUpgradeFundsAccessTitle,
            subtitle: Localization.hwUpgradeFundsAccessDescription
        )

        let securityTrait = TraitItem(
            icon: Assets.lock24,
            title: Localization.hwUpgradeGeneralSecurityTitle,
            subtitle: Localization.hwUpgradeGeneralSecurityDescription
        )

        return InfoItem(
            icon: Assets.tangemIconMedium,
            title: Localization.hwUpgradeTitle,
            traits: [keyTrait, fundsTrait, securityTrait]
        )
    }
}

// MARK: - Card operations

private extension MobileUpgradeViewModel {
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
                    viewModel.alert = error.alertBinder
                }

            case .onboarding:
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.alert = UpgradeError.cardBackupInProgress.alertBinder
                }

            case .scanTroubleshooting:
                Analytics.log(.cantScanTheCard, params: [.source: .introduction])
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.openTroubleshooting()
                }

            case .success(let cardInfo):
                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.handleSuccessScan(cardInfo: cardInfo)
                }
            }
        }
    }

    func handleSuccessScan(cardInfo: CardInfo) {
        // [REDACTED_TODO_COMMENT]
        // - if wallet is already created
        // - if product type == wallet2
        // - if settings.isKeysImportAllowed == true
    }
}

// MARK: - Navigation

private extension MobileUpgradeViewModel {
    func openOnboarding(cardInfo: CardInfo) {
        // [REDACTED_TODO_COMMENT]
        // coordinator?.openOnboarding(input: onboardingInput)
    }

    func openTroubleshooting() {
        let sheet = ActionSheet(
            title: Text(Localization.alertTroubleshootingScanCardTitle),
            message: Text(Localization.alertTroubleshootingScanCardMessage),
            buttons: [
                .default(
                    Text(Localization.alertButtonTryAgain),
                    action: weakify(self, forFunction: MobileUpgradeViewModel.scanCardTryAgain)
                ),
                .default(
                    Text(Localization.commonReadMore),
                    action: weakify(self, forFunction: MobileUpgradeViewModel.openScanCardManual)
                ),
                .default(
                    Text(Localization.alertButtonRequestSupport),
                    action: weakify(self, forFunction: MobileUpgradeViewModel.requestSupport)
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

    func close() {
        coordinator?.closeMobileUpgrade()
    }
}

// MARK: - Helpers

private extension MobileUpgradeViewModel {
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

// MARK: - Identifiable

extension MobileUpgradeViewModel: Identifiable {
    var id: AnyHashable { ObjectIdentifier(self) }
}

// MARK: - Types

extension MobileUpgradeViewModel {
    struct InfoItem {
        let icon: ImageType
        let title: String
        let traits: [TraitItem]
    }

    struct TraitItem: Identifiable {
        let id = UUID()
        let icon: ImageType
        let title: String
        let subtitle: String
    }

    enum UpgradeError: LocalizedError {
        case cardBackupInProgress

        var errorDescription: String? {
            switch self {
                // [REDACTED_TODO_COMMENT]
            case .cardBackupInProgress: "This card can’t be used for upgrade. Error code:"
            }
        }
    }
}
