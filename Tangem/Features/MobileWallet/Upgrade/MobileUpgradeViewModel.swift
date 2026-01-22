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

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private var analyticsCardScanSourceParameterValue: Analytics.ParameterValue {
        Analytics.CardScanSource.upgrade.cardWasScannedParameterValue
    }

    private let userWalletModel: UserWalletModel
    private let context: MobileWalletContext
    private weak var coordinator: MobileUpgradeRoutable?

    private var resetCardSetUtil: ResetToFactoryUtil?
    private var resetCardSetSubscription: AnyCancellable?

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
        logUpgradeTapAnalytics()
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
            icon: Assets.Glyphs.tangemUpgrade,
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
        logScanCardTapAnalytics()

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
                viewModel.logScanCardAnalytics(error: error)
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.alert = error.alertBinder
                }

            case .onboarding(_, let cardInfo):
                await runOnMain {
                    viewModel.incomingActionManager.discardIncomingAction()
                    viewModel.isScanning = false

                    if viewModel.needResetCardSet(cardInfo: cardInfo) {
                        viewModel.alert = viewModel.makeResetCardSetAlert(cardInfo: cardInfo)
                    } else {
                        viewModel.handleScan(cardInfo: cardInfo)
                    }
                }

            case .scanTroubleshooting:
                viewModel.logScanCardTroubleshootingAnalytics()
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.openTroubleshooting()
                }

            case .success(let cardInfo):
                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.incomingActionManager.discardIncomingAction()

                    if viewModel.needResetCardSet(cardInfo: cardInfo) {
                        viewModel.alert = viewModel.makeResetCardSetAlert(cardInfo: cardInfo)
                    } else {
                        viewModel.alert = UpgradeError.cardAlreadyHasWallet.alertBinder
                    }
                }
            }
        }
    }

    func needResetCardSet(cardInfo: CardInfo) -> Bool {
        UserWalletId(cardInfo: cardInfo) == userWalletModel.userWalletId
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

// MARK: - Reset card set

private extension MobileUpgradeViewModel {
    func makeResetCardSetAlert(cardInfo: CardInfo) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.resetCardsDialogFirstTitle,
            message: Localization.resetCardsDialogFirstDescription,
            primaryButton: .destructive(
                Text(Localization.commonReset),
                action: { [weak self] in
                    self?.resetCardSet(cardInfo: cardInfo)
                }
            ),
            secondaryButton: .default(Text(Localization.commonCancel))
        )
    }

    func resetCardSet(cardInfo: CardInfo) {
        let cardInteractor = FactorySettingsResettingCardInteractor(with: cardInfo)
        let backupCardsCount = cardInfo.card.backupStatus?.backupCardsCount ?? 0

        let resetUtil = ResetToFactoryUtilBuilder(flow: .upgrade).build(
            backupCardsCount: backupCardsCount,
            cardInteractor: cardInteractor
        )

        resetCardSetSubscription = resetUtil.alertPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, alert in
                viewModel.alert = alert
            }

        resetUtil.resetToFactory(onDidFinish: weakify(self, forFunction: MobileUpgradeViewModel.onDidFinishResetCardSet))

        resetCardSetUtil = resetUtil
    }

    func onDidFinishResetCardSet() {}
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
            self?.scanCardRequestSupport()
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
        logBuyHardwareWalletAnalytics()
        safariManager.openURL(TangemShopUrlBuilder().url(utmCampaign: .upgrade))
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
        logScanCardTryAgainAnalytics()
        scanCard()
    }

    func scanCardRequestSupport() {
        logScanCardRequestSupportAnalytics()
        failedCardScanTracker.resetCounter()
        openMail()
    }
}

// MARK: - Analytics

private extension MobileUpgradeViewModel {
    func logUpgradeTapAnalytics() {
        Analytics.log(.walletSettingsButtonStartUpgrade, contextParams: analyticsContextParams)
    }

    func logScanCardTapAnalytics() {
        Analytics.log(
            .introductionProcessButtonScanCard,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardTryAgainAnalytics() {
        Analytics.log(
            .cantScanTheCardTryAgainButton,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardRequestSupportAnalytics() {
        Analytics.log(
            .requestSupport,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardTroubleshootingAnalytics() {
        Analytics.log(
            .cantScanTheCard,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardAnalytics(error: Error) {
        Analytics.logScanError(error, source: .upgrade, contextParams: analyticsContextParams)
        Analytics.logVisaCardScanErrorIfNeeded(error, source: .upgrade)
    }

    func logBuyHardwareWalletAnalytics() {
        Analytics.log(
            .basicButtonBuy,
            params: [.source: Analytics.BuyWalletSource.upgrade.parameterValue],
            contextParams: analyticsContextParams
        )
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
