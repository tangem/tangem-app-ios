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
import TangemLocalization
import TangemAssets
import TangemSdk
import TangemNetworkUtils
import TangemMobileWalletSdk
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ConfirmationDialogViewModel

final class MobileUpgradeViewModel: ObservableObject {
    @Published var isScanning: Bool = false

    @Published var confirmationDialog: ConfirmationDialogViewModel?
    @Published var alert: AlertBinder?

    lazy var info = makeInfo()

    let buyButtonTitle = Localization.detailsBuyWallet
    let upgradeButtonTitle = Localization.hwUpgradeStartAction

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
    func onUpgradeTap() {
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

        let backupTrait = TraitItem(
            icon: Assets.Visa.securityCheck,
            title: Localization.hwUpgradeBackupTitle,
            subtitle: Localization.hwUpgradeBackupDescription
        )

        let securityTrait = TraitItem(
            icon: Assets.lock24,
            title: Localization.hwUpgradeGeneralSecurityTitle,
            subtitle: Localization.hwUpgradeGeneralSecurityDescription
        )

        return InfoItem(
            icon: Assets.tangemIconMedium,
            title: Localization.hwUpgradeTitle,
            traits: [keyTrait, backupTrait, securityTrait]
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

        let cardImageProvider = CardImageProvider(card: cardInfo.card)

        return OnboardingInput(
            backupService: backupService,
            primaryCardId: cardInfo.card.cardId,
            cardInitializer: cardInitializer,
            pushNotificationsPermissionManager: nil,
            steps: steps,
            cardInput: .userWalletModel(
                userWalletModel,
                cardId: cardInfo.card.cardId,
                cardImageProvider: cardImageProvider
            ),
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
        let tryAgainButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonTryAgain) { [weak self] in
            self?.scanCardTryAgain()
        }

        let readMoreButton = ConfirmationDialogViewModel.Button(title: Localization.commonReadMore) { [weak self] in
            self?.openScanCardManual()
        }

        let requestSupportButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonRequestSupport) { [weak self] in
            self?.requestSupport()
        }

        confirmationDialog = ConfirmationDialogViewModel(
            title: Localization.alertTroubleshootingScanCardTitle,
            subtitle: Localization.alertTroubleshootingScanCardMessage,
            buttons: [
                tryAgainButton,
                readMoreButton,
                requestSupportButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
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

        var errorDescription: String? {
            switch self {
            case .cardAlreadyHasWallet: Localization.hwUpgradeErrorCardAlreadyHasWallet
            case .wallet2CardRequired: Localization.hwUpgradeErrorWallet2CardRequired
            case .cardDoesNotAllowKeyImport: Localization.hwUpgradeErrorCardKeyImport
            }
        }
    }
}
