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
import TangemSdk
import TangemNetworkUtils
import TangemMobileWalletSdk

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

    private let userWalletModel: UserWalletModel
    private let context: MobileWalletContext
    private weak var coordinator: MobileUpgradeRoutable?

    init(
        userWalletModel: UserWalletModel,
        context: MobileWalletContext,
        coordinator: MobileUpgradeRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.context = context
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

    func makeOnboardingInput(cardInfo: CardInfo) -> OnboardingInput? {
        // Card for mobile backup must not have an access code set.
        let backupFactory = GenericBackupServiceFactory(isAccessCodeSet: false)
        let backupService = backupFactory.makeBackupService()

        if let primaryCard = cardInfo.primaryCard {
            backupService.setPrimaryCard(primaryCard)
        }

        let stepsBuilder = userWalletModel.config.makeOnboardingStepsBuilder(
            backupService: backupService
        )

        guard let steps = stepsBuilder.buildBackupSteps() else {
            return nil
        }

        // Card for tangem sdk does not have an access code set yet.
        let sdkFactory = GenericTangemSdkFactory(isAccessCodeSet: false)
        let tangemSdk = sdkFactory.makeTangemSdk()

        let cardInitializer = CommonCardInitializer(tangemSdk: tangemSdk, cardInfo: cardInfo)

        return OnboardingInput(
            backupService: backupService,
            primaryCardId: cardInfo.card.cardId,
            cardInitializer: cardInitializer,
            pushNotificationsPermissionManager: nil,
            steps: steps,
            cardInput: .userWalletModel(userWalletModel, cardId: cardInfo.card.cardId),
            twinData: nil,
            isStandalone: false,
            mobileContext: context
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

            case .onboarding(_, let cardInfo):
                await runOnMain {
                    viewModel.incomingActionManager.discardIncomingAction()
                    viewModel.isScanning = false
                    viewModel.handleScan(cardInfo: cardInfo)
                }

            case .scanTroubleshooting:
                Analytics.log(.cantScanTheCard, params: [.source: .introduction])
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.openTroubleshooting()
                }

            case .success:
                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.incomingActionManager.discardIncomingAction()
                    viewModel.alert = UpgradeError.cardAlreadyHasWallet.alertBinder
                }
            }
        }
    }

    func handleScan(cardInfo: CardInfo) {
        do {
            try validateCardForUpgrade(cardInfo: cardInfo)
            if let input = makeOnboardingInput(cardInfo: cardInfo) {
                openOnboarding(input: input)
            }
        } catch {
            alert = error.alertBinder
        }
    }

    func validateCardForUpgrade(cardInfo: CardInfo) throws {
        guard cardInfo.card.wallets.isEmpty else {
            throw UpgradeError.cardAlreadyHasWallet
        }

        guard cardInfo.card.firmwareVersion >= .ed25519Slip0010Available else {
            throw UpgradeError.wallet2CardRequired
        }

        guard cardInfo.card.settings.isKeysImportAllowed else {
            throw UpgradeError.cardDoesNotAllowKeyImport
        }
    }
}

// MARK: - Navigation

private extension MobileUpgradeViewModel {
    func openOnboarding(input: OnboardingInput) {
        coordinator?.openOnboarding(input: input)
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
        case cardAlreadyHasWallet
        case wallet2CardRequired
        case cardDoesNotAllowKeyImport

        // [REDACTED_TODO_COMMENT]
        var errorDescription: String? {
            switch self {
            case .cardAlreadyHasWallet: "Card already has wallet."
            case .wallet2CardRequired: "Wallet2 card is required."
            case .cardDoesNotAllowKeyImport: "Card does not allow key import."
            }
        }
    }
}
