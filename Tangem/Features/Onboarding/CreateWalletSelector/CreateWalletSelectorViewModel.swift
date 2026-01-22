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
import TangemAssets
import TangemLocalization
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ConfirmationDialogViewModel

final class CreateWalletSelectorViewModel: ObservableObject {
    @Published var isScanning: Bool = false

    @Published var scanTroubleshootingDialog: ConfirmationDialogViewModel?
    @Published var alert: AlertBinder?

    let backButtonHeight: CGFloat = OnboardingLayoutConstants.navbarSize.height

    let title = Localization.commonTangemWallet
    let description = Localization.welcomeCreateWalletHardwareDescription
    let scanTitle = Localization.welcomeUnlockCard
    let buyTitle = Localization.detailsBuyWallet
    let otherMethodTitle = Localization.welcomeCreateWalletOtherMethod

    lazy var chipItems: [ChipItem] = makeChipItems()
    lazy var mobileWalletItem: MobileWalletItem = makeMobileWalletItem()

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

    private let mobileWalletFeatureProvider = MobileWalletFeatureProvider()

    private var analyticsCardScanSourceParameterValue: Analytics.ParameterValue {
        Analytics.CardScanSource.createWalletIntro.cardWasScannedParameterValue
    }

    private weak var coordinator: CreateWalletSelectorRoutable?

    init(coordinator: CreateWalletSelectorRoutable) {
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension CreateWalletSelectorViewModel {
    func onFirstAppear() {
        logScreenOpenedAnalytics()
    }

    func onBackTap() {
        runTask(in: self) { viewModel in
            await viewModel.close()
        }
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
            ChipItem(icon: Assets.Glyphs.boldFlash, title: Localization.welcomeCreateWalletFeatureDelivery),
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
        guard mobileWalletFeatureProvider.isAvailable else {
            alert = mobileWalletFeatureProvider.makeRestrictionAlert()
            return
        }
        openCreateMobileWallet()
    }
}

// MARK: - Card operations

private extension CreateWalletSelectorViewModel {
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

            case .onboarding(let input, _):
                viewModel.logScanCardOnboardingAnalytics(cardInput: input.cardInput)
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.openOnboarding(options: .input(input))
                }

            case .scanTroubleshooting:
                viewModel.logScanCardTroubleshootingAnalytics()
                viewModel.incomingActionManager.discardIncomingAction()

                await MainActor.run {
                    viewModel.isScanning = false
                    viewModel.openTroubleshooting()
                }

            case .success(let cardInfo):
                viewModel.logScanCardSuccessAnalytics(cardInfo: cardInfo)

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

private extension CreateWalletSelectorViewModel {
    func openCreateMobileWallet() {
        logCreateNewWalletAnalytics()
        coordinator?.openCreateMobileWallet()
    }

    func openBuyHardwareWallet() {
        logBuyHardwareWalletAnalytics()
        safariManager.openURL(TangemShopUrlBuilder().url(utmCampaign: .prospect))
    }

    func openOnboarding(options: OnboardingCoordinator.Options) {
        coordinator?.openOnboarding(options: options)
    }

    func openMain(userWalletModel: UserWalletModel) {
        coordinator?.openMain(userWalletModel: userWalletModel)
    }

    @MainActor
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

        scanTroubleshootingDialog = ConfirmationDialogViewModel(
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
}

// MARK: - Helpers

private extension CreateWalletSelectorViewModel {
    func scanCardTryAgain() {
        logScanCardTryAgainAnalytics()
        scanCard()
    }

    @MainActor
    func requestSupport() {
        logScanCardRequestSupportAnalytics()
        failedCardScanTracker.resetCounter()
        openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient)
    }

    @MainActor
    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)

        mailPresenter.present(viewModel: mailViewModel)
    }

    @MainActor
    func close() {
        coordinator?.closeCreateWalletSelector()
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }
}

// MARK: - Analytics

private extension CreateWalletSelectorViewModel {
    func logScreenOpenedAnalytics() {
        Analytics.log(.introductionProcessCreateWalletIntroScreenOpened)
    }

    func logScanCardTapAnalytics() {
        Analytics.log(
            Analytics.CardScanSource.welcome.cardScanButtonEvent,
            params: [.source: analyticsCardScanSourceParameterValue]
        )
    }

    func logScanCardAnalytics(error: Error) {
        Analytics.logScanError(error, source: .introduction)
        Analytics.logVisaCardScanErrorIfNeeded(error, source: .introduction)
    }

    func logScanCardOnboardingAnalytics(cardInput: OnboardingInput.CardInput) {
        Analytics.log(
            .cardWasScanned,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: cardInput.getContextParams()
        )
    }

    func logScanCardSuccessAnalytics(cardInfo: CardInfo) {
        Analytics.log(
            .cardWasScanned,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: .custom(cardInfo.analyticsContextData)
        )
    }

    func logScanCardTryAgainAnalytics() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: analyticsCardScanSourceParameterValue])
    }

    func logScanCardTroubleshootingAnalytics() {
        Analytics.log(.cantScanTheCard, params: [.source: analyticsCardScanSourceParameterValue])
    }

    func logScanCardRequestSupportAnalytics() {
        Analytics.log(.requestSupport, params: [.source: analyticsCardScanSourceParameterValue])
    }

    func logCreateNewWalletAnalytics() {
        Analytics.log(.buttonMobileWallet, params: [.source: analyticsCardScanSourceParameterValue])
    }

    func logBuyHardwareWalletAnalytics() {
        Analytics.log(.basicButtonBuy, params: [.source: analyticsCardScanSourceParameterValue])
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
