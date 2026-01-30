//
//  MainCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import BlockchainSdk
import TangemVisa
import TangemNFT
import TangemFoundation
import TangemUI
import TangemMobileWalletSdk
import struct TangemUIUtils.AlertBinder

final class MainCoordinator: CoordinatorObject, FeeCurrencyNavigating {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.mobileFinishActivationManager) private var mobileFinishActivationManager: MobileFinishActivationManager

    private let coordinatorFactory: MainCoordinatorChildFactory
    private let navigationActionHandler: MainNavigationActionHandler
    private let deeplinkPresenter: DeeplinkPresenter

    // MARK: - Root view model

    @Published private(set) var mainViewModel: MainViewModel?

    // MARK: - Child coordinators (Push presentation)

    @Published var detailsCoordinator: DetailsCoordinator?
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?
    @Published var marketsTokenDetailsCoordinator: MarketsTokenDetailsCoordinator?
    @Published var stakingDetailsCoordinator: StakingDetailsCoordinator?
    @Published var nftCollectionsCoordinator: NFTCollectionsCoordinator?
    @Published var yieldModulePromoCoordinator: YieldModulePromoCoordinator?
    @Published var yieldModuleActiveCoordinator: YieldModuleActiveCoordinator?

    // MARK: - Child coordinators (Other)

    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var actionButtonsBuyCoordinator: ActionButtonsBuyCoordinator? = nil
    @Published var actionButtonsSellCoordinator: ActionButtonsSellCoordinator? = nil
    @Published var actionButtonsSwapCoordinator: ActionButtonsSwapCoordinator? = nil
    @Published var mobileUpgradeCoordinator: MobileUpgradeCoordinator? = nil
    @Published var tangemPayMainCoordinator: TangemPayMainCoordinator?
    @Published var tangemPayOnboardingCoordinator: TangemPayOnboardingCoordinator?
    @Published var mobileBackupTypesCoordinator: MobileBackupTypesCoordinator?

    // MARK: - Child view models

    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel?
    @Published var organizeTokensViewModel: AccountsAwareOrganizeTokensViewModel?
    @available(iOS, deprecated: 100000.0, message: "Superseded by 'organizeTokensViewModel', will be removed in the future ([REDACTED_INFO])")
    @Published var legacyOrganizeTokensViewModel: OrganizeTokensViewModel?
    @Published var pushNotificationsViewModel: PushNotificationsPermissionRequestViewModel?
    @Published var visaTransactionDetailsViewModel: VisaTransactionDetailsViewModel?
    @Published var pendingExpressTxStatusBottomSheetViewModel: PendingExpressTxStatusBottomSheetViewModel? = nil

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false
    @Published var isAppStoreReviewRequested = false
    @Published var isMarketsTooltipVisible = false

    // MARK: - Deeplink

    private var deeplinkDestination = PassthroughSubject<DeepLinkDestination, Never>()

    private var safariHandle: SafariHandle?
    private var pushNotificationsViewModelSubscription: AnyCancellable?
    private var deeplinkDestinationSubscription: AnyCancellable?

    required init(
        coordinatorFactory: MainCoordinatorChildFactory,
        navigationActionHandler: MainNavigationActionHandler,
        deeplinkPresenter: DeeplinkPresenter,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.coordinatorFactory = coordinatorFactory
        self.navigationActionHandler = navigationActionHandler
        self.deeplinkPresenter = deeplinkPresenter
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let swipeDiscoveryHelper = WalletSwipeDiscoveryHelper()
        let factory = PushNotificationsHelpersFactory()
        let pushNotificationsAvailabilityProvider = factory.makeAvailabilityProviderForAfterLogin(using: pushNotificationsInteractor)
        let viewModel = MainViewModel(
            selectedUserWalletId: options.userWalletModel.userWalletId,
            coordinator: self,
            swipeDiscoveryHelper: swipeDiscoveryHelper,
            mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: self),
            pushNotificationsAvailabilityProvider: pushNotificationsAvailabilityProvider
        )

        swipeDiscoveryHelper.delegate = viewModel
        mainViewModel = viewModel

        mobileFinishActivationManager.observe(
            userWalletId: options.userWalletModel.userWalletId,
            onActivation: weakify(self, forFunction: MainCoordinator.openMobileFinishActivation)
        )

        setupUI()
        bind()
    }

    func hideMarketsTooltip() {
        AppSettings.shared.marketsTooltipWasShown = true

        withAnimation(.easeInOut(duration: Constants.tooltipAnimationDuration)) {
            isMarketsTooltipVisible = false
        }
    }

    // MARK: - Private Implementation

    private func bind() {
        deeplinkDestinationSubscription = deeplinkDestination
            .compactMap { $0 }
            .receiveOnMain()
            .sink { [weak self] deepLink in
                self?.deeplinkPresenter.present(deepLink: deepLink)
            }

        if pushNotificationsViewModelSubscription == nil {
            pushNotificationsViewModelSubscription = $pushNotificationsViewModel
                .pairwise()
                .filter { previous, current in
                    // Transition from a non-nil value to a nil value, i.e. dismissing the sheet
                    previous != nil && current == nil
                }
                .sink { previous, _ in
                    previous?.didDismissSheet()
                }
        }
    }

    private func setupUI() {
        showMarketsTooltip()
    }

    private func showMarketsTooltip() {
        // Don't show markets tooltip during UI testing
        guard !AppEnvironment.current.isUITest else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.tooltipAnimationDelay) { [weak self] in
            guard let self else {
                self?.isMarketsTooltipVisible = false
                return
            }

            withAnimation(.easeInOut(duration: Constants.tooltipAnimationDuration)) {
                self.isMarketsTooltipVisible = !AppSettings.shared.marketsTooltipWasShown
            }
        }
    }
}

// MARK: - Options

extension MainCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
    }
}

// MARK: - MainRoutable protocol conformance

extension MainCoordinator: MainRoutable {
    func beginHandlingIncomingActions() {
        navigationActionHandler.becomeIncomingActionsResponder()
    }

    func resignHandlingIncomingActions() {
        navigationActionHandler.resignIncomingActionsResponder()
    }

    func openDeepLink(_ deepLink: DeepLinkDestination) {
        if case .externalLink(let url) = deepLink {
            safariManager.openURL(url)
        } else {
            deeplinkDestination.send(deepLink)
        }
    }

    func openDetails() {
        mainBottomSheetUIManager.hide()

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.detailsCoordinator = nil
        }

        let coordinator = DetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .default)
        detailsCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    func openOnboardingModal(with options: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] _ in
            self?.modalOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func close(newScan: Bool) {
        popToRoot(with: .init(newScan: newScan))
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }

    func openPushNotificationsAuthorization() {
        let factory = PushNotificationsHelpersFactory()
        let permissionManager = factory.makePermissionManagerForAfterLogin(using: pushNotificationsInteractor)
        pushNotificationsViewModel = PushNotificationsPermissionRequestViewModel(permissionManager: permissionManager, delegate: self)
    }
}

// MARK: - MultiWalletMainContentRoutable protocol conformance

extension MainCoordinator: MultiWalletMainContentRoutable {
    func openYieldModulePromoView(apy: Decimal, factory: YieldModuleFlowFactory) {
        let dismissAction: Action<YieldModulePromoCoordinator.DismissOptions?> = { [weak self] option in
            self?.yieldModulePromoCoordinator = nil
            self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
        }

        mainBottomSheetUIManager.hide()
        let coordinator = factory.makeYieldPromoCoordinator(apy: apy, dismissAction: dismissAction)
        yieldModulePromoCoordinator = coordinator
    }

    func openGetTangemPay() {
        let dismissAction: Action<TangemPayOnboardingCoordinator.DismissOptions?> = { [weak self] _ in
            self?.tangemPayOnboardingCoordinator = nil
        }

        let coordinator = TangemPayOnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(source: .other))
        tangemPayOnboardingCoordinator = coordinator
    }

    func openYieldModuleActiveInfo(factory: YieldModuleFlowFactory) {
        let dismissAction: Action<YieldModuleActiveCoordinator.DismissOptions?> = { [weak self] option in
            self?.yieldModuleActiveCoordinator = nil
            self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
        }

        let coordinator = factory.makeYieldActiveCoordinator(dismissAction: dismissAction)
        yieldModuleActiveCoordinator = coordinator
    }

    func openTokenDetails(for model: any WalletModel, userWalletModel: UserWalletModel) {
        mainBottomSheetUIManager.hide()

        let coordinator = coordinatorFactory.makeTokenDetailsCoordinator(dismissAction: { [weak self] in
            self?.tokenDetailsCoordinator = nil
        })

        coordinator.start(with: .init(userWalletModel: userWalletModel, walletModel: model))
        tokenDetailsCoordinator = coordinator
    }

    func openOrganizeTokens(for userWalletModel: UserWalletModel) {
        if FeatureProvider.isAvailable(.accounts) {
            organizeTokensViewModel = AccountsAwareOrganizeTokensViewModel(
                userWalletModel: userWalletModel,
                coordinator: self
            )
        } else {
            // accounts_fixes_needed_none
            let userTokensManager = userWalletModel.userTokensManager
            let optionsManager = OrganizeTokensOptionsManager(userTokensReorderer: userTokensManager)
            let tokenSectionsAdapter = TokenSectionsAdapter(
                userTokensManager: userTokensManager,
                optionsProviding: optionsManager,
                preservesLastSortedOrderOnSwitchToDragAndDrop: true
            )
            legacyOrganizeTokensViewModel = OrganizeTokensViewModel(
                userWalletModel: userWalletModel,
                tokenSectionsAdapter: tokenSectionsAdapter,
                optionsProviding: optionsManager,
                optionsEditing: optionsManager,
                coordinator: self
            )
        }
    }

    func openMobileFinishActivation(userWalletModel: UserWalletModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: MobileFinishActivationNeededViewModel(userWalletModel: userWalletModel, coordinator: self)
            )
        }
    }

    func openMobileUpgrade(userWalletModel: UserWalletModel, context: MobileWalletContext) {
        Task { @MainActor in
            let dismissAction: Action<MobileUpgradeCoordinator.OutputOptions> = { [weak self] options in
                switch options {
                case .dismiss, .main:
                    self?.mobileUpgradeCoordinator = nil
                }
            }

            let coordinator = MobileUpgradeCoordinator(dismissAction: dismissAction)
            let inputOptions = MobileUpgradeCoordinator.InputOptions(userWalletModel: userWalletModel, context: context)
            coordinator.start(with: inputOptions)
            mobileUpgradeCoordinator = coordinator
        }
    }

    func openTangemPayIssuingYourCardPopup() {
        let viewModel = TangemPayYourCardIsIssuingSheetViewModel(coordinator: self)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayKYCInProgressPopup(tangemPayAccount: TangemPayAccount) {
        let viewModel = TangemPayKYCStatusPopupViewModel(
            tangemPayAccount: tangemPayAccount,
            coordinator: self
        )
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayFailedToIssueCardPopup(userWalletModel: UserWalletModel) {
        let viewModel = TangemPayFailedToIssueCardSheetViewModel(userWalletModel: userWalletModel, coordinator: self)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayMainView(userWalletInfo: UserWalletInfo, tangemPayAccount: TangemPayAccount) {
        mainBottomSheetUIManager.hide()

        let coordinator = TangemPayMainCoordinator(
            dismissAction: makeExpressCoordinatorDismissAction(),
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(userWalletInfo: userWalletInfo, tangemPayAccount: tangemPayAccount))
        tangemPayMainCoordinator = coordinator
    }
}

// MARK: - SingleTokenBaseRoutable

extension MainCoordinator: SingleTokenBaseRoutable {
    func openReceiveScreen(walletModel: any WalletModel) {
        let receiveFlowFactory = AvailabilityReceiveFlowFactory(
            flow: .crypto,
            tokenItem: walletModel.tokenItem,
            addressTypesProvider: walletModel,
            // [REDACTED_TODO_COMMENT]
            isYieldModuleActive: false
        )

        switch receiveFlowFactory.makeAvailabilityReceiveFlow() {
        case .bottomSheetReceiveFlow(let viewModel):
            receiveBottomSheetViewModel = viewModel
        case .domainReceiveFlow(let viewModel):
            Task { @MainActor in
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }
        }
    }

    func openSellCrypto(at url: URL, action: @escaping (String) -> Void) {
        Analytics.log(.withdrawScreenOpened)

        safariHandle = safariManager.openURL(url) { [weak self] closeURL in
            self?.safariHandle = nil
            action(closeURL.absoluteString)
        }
    }

    func openSend(input: SendInput) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(input: input, type: .send, source: .main)

        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openSendToSell(input: SendInput, sellParameters: PredefinedSellParameters) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(
            input: input,
            type: .sell(parameters: sellParameters),
            source: .main
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openExpress(input: ExpressDependenciesInput) {
        let factory = CommonExpressModulesFactory(input: input)
        let coordinator = makeExpressCoordinator(factory: factory)

        let openExpressBlock = { [weak self] in
            coordinator.start(with: .default)
            self?.expressCoordinator = coordinator
        }

        Task { @MainActor [tangemStoriesPresenter] in
            tangemStoriesPresenter.present(
                story: .swap(.initialWithoutImages),
                analyticsSource: .tokenListContextMenu,
                presentCompletion: openExpressBlock
            )
        }
    }

    func openStaking(options: StakingDetailsCoordinator.Options) {
        mainBottomSheetUIManager.hide()

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.stakingDetailsCoordinator = nil
        }

        let coordinator = StakingDetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: options)
        stakingDetailsCoordinator = coordinator
    }

    func openInSafari(url: URL) {
        safariManager.openURL(url)
    }

    func openMarketsTokenDetails(tokenModel: MarketsTokenModel) {
        mainBottomSheetUIManager.hide()
        let coordinator = coordinatorFactory.makeMarketsTokenDetailsCoordinator()
        coordinator.start(with: .init(info: tokenModel, style: .defaultNavigationStack))
        marketsTokenDetailsCoordinator = coordinator
    }

    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters) {
        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(
            input: input,
            type: .onramp(parameters: parameters),
            source: .main
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openPendingExpressTransactionDetails(
        pendingTransaction: PendingTransaction,
        tokenItem: TokenItem,
        userWalletInfo: UserWalletInfo,
        pendingTransactionsManager: PendingExpressTransactionsManager
    ) {
        pendingExpressTxStatusBottomSheetViewModel = PendingExpressTxStatusBottomSheetViewModel(
            pendingTransaction: pendingTransaction,
            currentTokenItem: tokenItem,
            userWalletInfo: userWalletInfo,
            pendingTransactionsManager: pendingTransactionsManager,
            router: self
        )
    }
}

// MARK: - SendFeeCurrencyNavigating, ExpressFeeCurrencyNavigating {

extension MainCoordinator: SendFeeCurrencyNavigating, ExpressFeeCurrencyNavigating {
    func openFeeCurrency(for model: any WalletModel, userWalletModel: UserWalletModel) {
        // We add custom implementation because we have to call
        // `mainBottomSheetUIManager.hide()` from main
        openTokenDetails(for: model, userWalletModel: userWalletModel)
    }
}

// MARK: - OrganizeTokensRoutable protocol conformance

extension MainCoordinator: OrganizeTokensRoutable {
    func didTapCancelButton() {
        organizeTokensViewModel = nil
        legacyOrganizeTokensViewModel = nil
    }

    func didTapSaveButton() {
        organizeTokensViewModel = nil
        legacyOrganizeTokensViewModel = nil
    }
}

// MARK: - Visa

extension MainCoordinator: VisaWalletRoutable {
    func openTransactionDetails(tokenItem: TokenItem, for record: VisaTransactionRecord, emailConfig: EmailConfig) {
        visaTransactionDetailsViewModel = .init(tokenItem: tokenItem, transaction: record, emailConfig: emailConfig, router: self)
    }

    func openReceiveScreen(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo]) {
        let addressTypesProvider = VisaReceiveAssetInfoProvider(addressInfos)

        let receiveFlowFactory = AvailabilityReceiveFlowFactory(
            flow: .crypto,
            tokenItem: tokenItem,
            addressTypesProvider: addressTypesProvider,
            // [REDACTED_TODO_COMMENT]
            isYieldModuleActive: false
        )

        switch receiveFlowFactory.makeAvailabilityReceiveFlow() {
        case .bottomSheetReceiveFlow(let viewModel):
            receiveBottomSheetViewModel = viewModel
        case .domainReceiveFlow(let viewModel):
            Task { @MainActor in
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }
        }
    }
}

extension MainCoordinator: VisaTransactionDetailsRouter {}

extension MainCoordinator: TangemPayYourCardIsIssuingRoutable {
    func closeYourCardIsIssuingSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

extension MainCoordinator: TangemPayFailedToIssueCardRoutable {
    func closeFailedToIssueCardSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openMailFromFailedToIssueCardSheet(mailViewModel: MailViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            mailPresenter.present(viewModel: mailViewModel)
        }
    }
}

// MARK: - RateAppRoutable protocol conformance

extension MainCoordinator: RateAppRoutable {
    func openAppStoreReview() {
        isAppStoreReviewRequested = true
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate protocol conformance

extension MainCoordinator: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        pushNotificationsViewModel = nil
    }
}

// MARK: - Action buttons buy routable

extension MainCoordinator: ActionButtonsBuyFlowRoutable {
    func openBuy(userWalletModel: some UserWalletModel) {
        let coordinator = coordinatorFactory.makeBuyCoordinator(
            dismissAction: { [weak self] _ in
                self?.actionButtonsBuyCoordinator = nil
            }
        )

        let options: ActionButtonsBuyCoordinator.Options = if FeatureProvider.isAvailable(.accounts) {
            .new
        } else {
            .default(options: .init(
                userWalletModel: userWalletModel,
                expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletId: userWalletModel.userWalletId),
                tokenSorter: CommonBuyTokenAvailabilitySorter(userWalletModelConfig: userWalletModel.config)
            ))
        }

        coordinator.start(with: options)
        actionButtonsBuyCoordinator = coordinator
    }
}

// MARK: - Action buttons sell routable

extension MainCoordinator: ActionButtonsSellFlowRoutable {
    func openSell(userWalletModel: some UserWalletModel) {
        let coordinator = coordinatorFactory.makeSellCoordinator(
            userWalletModel: userWalletModel,
            dismissAction: { [weak self] model in
                self?.actionButtonsSellCoordinator = nil
                guard let model else { return }

                let input = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: model.walletModel)
                self?.openSendToSell(input: input, sellParameters: model.sellParameters)
            }
        )

        coordinator.start(with: FeatureProvider.isAvailable(.accounts) ? .new : .default)
        actionButtonsSellCoordinator = coordinator
    }
}

// MARK: - ActionButtonsSwapFlowRoutable

extension MainCoordinator: ActionButtonsSwapFlowRoutable {
    func openSwap(userWalletModel: some UserWalletModel) {
        let coordinator = coordinatorFactory.makeSwapCoordinator(userWalletModel: userWalletModel) { [weak self] _ in
            self?.actionButtonsSwapCoordinator = nil
        }

        Task { @MainActor [tangemStoriesPresenter] in
            tangemStoriesPresenter.present(
                story: .swap(.initialWithoutImages),
                analyticsSource: .main,
                presentCompletion: { [weak self] in
                    coordinator.start(with: FeatureProvider.isAvailable(.accounts) ? .new : .default)
                    self?.actionButtonsSwapCoordinator = coordinator
                }
            )
        }
    }
}

// MARK: - PendingExpressTxStatusRoutable

extension MainCoordinator: PendingExpressTxStatusRoutable {
    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func openRefundCurrency(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        pendingExpressTxStatusBottomSheetViewModel = nil
        openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
    }

    func dismissPendingTxSheet() {
        pendingExpressTxStatusBottomSheetViewModel = nil
    }
}

extension MainCoordinator {
    enum Constants {
        static let tooltipAnimationDuration: Double = 0.3
        static let tooltipAnimationDelay: Double = 1.5
    }
}

extension MainCoordinator: TangemPayKYCStatusRoutable {
    func closeKYCStatusPopup() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - NFTEntrypointRoutable

extension MainCoordinator: NFTEntrypointRoutable {
    func openCollections(
        nftManager: NFTManager,
        accounForNFTCollectionsProvider: any AccountForNFTCollectionProviding,
        navigationContext: NFTNavigationContext
    ) {
        mainBottomSheetUIManager.hide()

        let coordinator = NFTCollectionsCoordinator(
            dismissAction: { [weak self] in
                self?.nftCollectionsCoordinator = nil
            },
            popToRootAction: { [weak self] options in
                self?.nftCollectionsCoordinator = nil
                self?.popToRoot(with: options)
            }
        )

        coordinator.start(
            with: .init(
                nftManager: nftManager,
                accounForNFTCollectionsProvider: accounForNFTCollectionsProvider,
                navigationContext: navigationContext,
                nftChainIconProvider: NetworkImageProvider(),
                nftChainNameProvider: NFTChainNameProvider(),
                priceFormatter: NFTPriceFormatter(),
                blockchainSelectionAnalytics: NFTAnalytics.BlockchainSelection(
                    logBlockchainChosen: { blockchain in
                        Analytics.log(event: .nftReceiveBlockchainChosen, params: [.blockchain: blockchain])
                    }
                )
            )
        )

        nftCollectionsCoordinator = coordinator
    }
}

// MARK: - WCTransactionRoutable

extension MainCoordinator: WCTransactionRoutable {
    func show(floatingSheetViewModel: some FloatingSheetContentViewModel) {
        UIApplication.mainWindow?.endEditing(true)
        floatingSheetPresenter.enqueue(sheet: floatingSheetViewModel)
    }

    func show(toast: Toast<WarningToast>) {
        toast.present(layout: .top(padding: 20), type: .temporary())
    }
}

// MARK: - MainCoordinator

extension MainCoordinator {
    enum DeepLinkDestination {
        case expressTransactionStatus(walletModel: any WalletModel, userWalletModel: UserWalletModel, transactionDetails: PendingTransactionDetails)
        case tokenDetails(walletModel: any WalletModel, userWalletModel: UserWalletModel)
        case buy(userWalletModel: UserWalletModel)
        case sell(userWalletModel: UserWalletModel)
        case swap(userWalletModel: UserWalletModel)
        case referral(input: ReferralInputModel)
        case staking(options: StakingDetailsCoordinator.Options)
        case marketsTokenDetails(tokenId: String)
        case externalLink(url: URL)
        case market
        case onboardVisa(deeplinkString: String)
        case promo(code: String, refcode: String?, campaign: String?)
    }
}

// MARK: - MobileFinishActivationNeededRoutable

extension MainCoordinator: MobileFinishActivationNeededRoutable {
    func dismissMobileFinishActivationNeeded() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openMobileBackup(userWalletModel: UserWalletModel) {
        mainBottomSheetUIManager.hide()

        let dismissAction: Action<MobileBackupTypesCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main:
                self?.mobileBackupTypesCoordinator = nil
            }
        }

        let inputOptions = MobileBackupTypesCoordinator.InputOptions(userWalletModel: userWalletModel, mode: .activate)
        let coordinator = MobileBackupTypesCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        mobileBackupTypesCoordinator = coordinator
    }

    func openMobileBackupOnboarding(userWalletModel: UserWalletModel) {
        Task { @MainActor in
            let backupInput = MobileOnboardingInput(flow: .walletActivate(
                userWalletModel: userWalletModel,
                source: .main(action: .backup)
            ))
            openOnboardingModal(with: .mobileInput(backupInput))
        }
    }
}
