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

    @Published var confirmationDialog: ConfirmationDialogViewModel?
    @Published var alert: AlertBinder?

    let screenTitle = Localization.hardwareWalletCreateTitle
    let buyButtonTitle = Localization.detailsBuyWallet
    let scanButtonTitle = Localization.homeButtonScan

    lazy var infoItems: [InfoItem] = makeInfoItems()

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

    private var analyticsContextParams: Analytics.ContextParams {
        guard let userWalletModel else { return .empty }
        return .custom(userWalletModel.analyticsContextData)
    }

    private let userWalletModel: UserWalletModel?
    private let source: HardwareCreateWalletSource
    private weak var coordinator: HardwareCreateWalletRoutable?

    init(
        userWalletModel: UserWalletModel?,
        source: HardwareCreateWalletSource,
        coordinator: HardwareCreateWalletRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.source = source
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension HardwareCreateWalletViewModel {
    func onFirstAppear() {
        logScreenOpenedAnalytics()
    }

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
            icon: Assets.Glyphs.keySecurity,
            title: Localization.hardwareWalletKeyFeatureTitle,
            subtitle: Localization.hardwareWalletKeyFeatureDescription
        )

        let backupTrait = InfoItem(
            icon: Assets.Glyphs.twinSparkles,
            title: Localization.hardwareWalletBackupFeatureTitle,
            subtitle: Localization.hardwareWalletBackupFeatureDescription
        )

        let securityTrait = InfoItem(
            icon: Assets.lock24,
            title: Localization.hardwareWalletSecurityFeatureTitle,
            subtitle: Localization.hardwareWalletSecurityFeatureDescription
        )

        return [keyTrait, backupTrait, securityTrait]
    }
}

// MARK: - Card operations

private extension HardwareCreateWalletViewModel {
    func scanCard() {
        logScanCardTapAnalytics()

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
                viewModel.logScanCardAnalytics(error: error)
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.alert = error.alertBinder
                }

            case .onboarding(let input, let cardInfo):
                viewModel.logScanCardOnboardingAnalytics()
                viewModel.incomingActionManager.discardIncomingAction()

                do {
                    let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

                    if let userWalletId = UserWalletId(config: config),
                       viewModel.userWalletRepository.models.contains(where: { $0.userWalletId == userWalletId }) {
                        throw UserWalletRepositoryError.duplicateWalletAdded
                    }

                    await runOnMain {
                        viewModel.isScanning = false
                        viewModel.openOnboarding(input: input)
                    }
                } catch {
                    await runOnMain {
                        viewModel.isScanning = false
                        viewModel.alert = error.alertBinder
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
                viewModel.logScanCardSuccessAnalytics()

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
        let tryAgainButton = ConfirmationDialogViewModel.Button(
            title: Localization.alertButtonTryAgain,
            action: weakify(self, forFunction: HardwareCreateWalletViewModel.scanCardTryAgain)
        )

        let readMoreButton = ConfirmationDialogViewModel.Button(
            title: Localization.commonReadMore,
            action: weakify(self, forFunction: HardwareCreateWalletViewModel.openScanCardManual)
        )

        let requestSupportButton = ConfirmationDialogViewModel.Button(
            title: Localization.alertButtonRequestSupport,
            action: weakify(self, forFunction: HardwareCreateWalletViewModel.scanCardRequestSupport)
        )

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
        let utmCampaign: TangemUTM.Campaign = switch source {
        case .addNewWallet: .users
        case .hardwareWallet: .upgrade
        }
        safariManager.openURL(TangemShopUrlBuilder().url(utmCampaign: utmCampaign))
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

private extension HardwareCreateWalletViewModel {
    func logScreenOpenedAnalytics() {
        Analytics.log(.walletSettingsCreateWalletScreenOpened, contextParams: analyticsContextParams)
    }

    func logScanCardTapAnalytics() {
        Analytics.log(
            Analytics.CardScanSource.createWallet.cardScanButtonEvent,
            params: [.source: .create],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardSuccessAnalytics() {
        Analytics.log(
            .cardWasScanned,
            params: [.source: Analytics.CardScanSource.createWallet.cardWasScannedParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardOnboardingAnalytics() {
        Analytics.log(
            .cardWasScanned,
            params: [.source: Analytics.CardScanSource.createWallet.cardWasScannedParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardTryAgainAnalytics() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .introduction], contextParams: analyticsContextParams)
    }

    func logScanCardTroubleshootingAnalytics() {
        Analytics.log(.cantScanTheCard, params: [.source: .introduction], contextParams: analyticsContextParams)
    }

    func logScanCardRequestSupportAnalytics() {
        Analytics.log(.requestSupport, params: [.source: .introduction], contextParams: analyticsContextParams)
    }

    func logScanCardAnalytics(error: Error) {
        Analytics.logScanError(error, source: .introduction, contextParams: analyticsContextParams)
        Analytics.logVisaCardScanErrorIfNeeded(error, source: .introduction)
    }

    func logBuyHardwareWalletAnalytics() {
        Analytics.log(
            .basicButtonBuy,
            params: [.source: Analytics.BuyWalletSource.createWallet.parameterValue],
            contextParams: analyticsContextParams
        )
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
