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

class MainCoordinator: CoordinatorObject, FeeCurrencyNavigating {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

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
    @Published var referralCoordinator: ReferralCoordinator?
    @Published var nftCollectionsCoordinator: NFTCollectionsCoordinator?

    // MARK: - Child coordinators (Other)

    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var actionButtonsBuyCoordinator: ActionButtonsBuyCoordinator? = nil
    @Published var actionButtonsSellCoordinator: ActionButtonsSellCoordinator? = nil
    @Published var actionButtonsSwapCoordinator: ActionButtonsSwapCoordinator? = nil

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?
    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel?
    @Published var organizeTokensViewModel: OrganizeTokensViewModel?
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

    func openDetails(for userWalletModel: UserWalletModel) {
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
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
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
    func openTokenDetails(for model: any WalletModel, userWalletModel: UserWalletModel) {
        mainBottomSheetUIManager.hide()

        let coordinator = coordinatorFactory.makeTokenDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.tokenDetailsCoordinator = nil
            }
        )

        coordinator.start(
            with: .init(
                userWalletModel: userWalletModel,
                walletModel: model,
                userTokensManager: userWalletModel.userTokensManager,
                pendingTransactionDetails: nil
            )
        )

        tokenDetailsCoordinator = coordinator
    }

    func openOrganizeTokens(for userWalletModel: UserWalletModel) {
        let optionsManager = OrganizeTokensOptionsManager(userTokensReorderer: userWalletModel.userTokensManager)
        let tokenSectionsAdapter = TokenSectionsAdapter(
            userTokenListManager: userWalletModel.userTokenListManager,
            optionsProviding: optionsManager,
            preservesLastSortedOrderOnSwitchToDragAndDrop: true
        )
        organizeTokensViewModel = OrganizeTokensViewModel(
            coordinator: self,
            userWalletModel: userWalletModel,
            tokenSectionsAdapter: tokenSectionsAdapter,
            optionsProviding: optionsManager,
            optionsEditing: optionsManager
        )
    }

    func openReferral(input: ReferralInputModel) {
        mainBottomSheetUIManager.hide()
        let coordinator = coordinatorFactory.makeReferralCoordinator(
            dismissAction: { [weak self] _ in
                self?.referralCoordinator = nil
            }
        )

        coordinator.start(with: .init(input: input))
        referralCoordinator = coordinator
        Analytics.log(.referralScreenOpened)
    }

    func openHotFinishActivation(userWalletModel: UserWalletModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: HotFinishActivationNeededViewModel(userWalletModel: userWalletModel, routable: self)
            )
        }
    }
}

// MARK: - SingleTokenBaseRoutable

extension MainCoordinator: SingleTokenBaseRoutable {
    func openReceiveScreen(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo]) {
        receiveBottomSheetViewModel = ReceiveBottomSheetUtils(flow: .crypto).makeViewModel(
            for: tokenItem,
            addressInfos: addressInfos
        )
    }

    func openBuyCrypto(at url: URL, action: @escaping () -> Void) {
        Analytics.log(.topupScreenOpened)

        safariHandle = safariManager.openURL(url) { [weak self] _ in
            self?.safariHandle = nil
            action()
        }
    }

    func openSellCrypto(at url: URL, action: @escaping (String) -> Void) {
        Analytics.log(.withdrawScreenOpened)

        safariHandle = safariManager.openURL(url) { [weak self] closeURL in
            self?.safariHandle = nil
            action(closeURL.absoluteString)
        }
    }

    func openSend(userWalletModel: UserWalletModel, walletModel: any WalletModel) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .send,
            source: .main
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openSendToSell(amountToSend: Decimal, destination: String, tag: String?, userWalletModel: UserWalletModel, walletModel: any WalletModel) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .sell(parameters: .init(amount: amountToSend, destination: destination, tag: tag)),
            source: .main
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openExpress(input: CommonExpressModulesFactory.InputModel) {
        let dismissAction: Action<(walletModel: any WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.expressCoordinator = nil

            guard let navigationInfo else {
                return
            }

            self?.openFeeCurrency(for: navigationInfo.walletModel, userWalletModel: navigationInfo.userWalletModel)
        }

        let factory = CommonExpressModulesFactory(inputModel: input)
        let coordinator = ExpressCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        let openExpressBlock = { [weak self] in
            guard let self else { return }
            coordinator.start(with: .default)
            expressCoordinator = coordinator
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

    func openOnramp(walletModel: any WalletModel, userWalletModel: UserWalletModel) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] _ in
            self?.sendCoordinator = nil
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .onramp,
            source: .main
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openPendingExpressTransactionDetails(
        pendingTransaction: PendingTransaction,
        tokenItem: TokenItem,
        userWalletModel: UserWalletModel,
        pendingTransactionsManager: PendingExpressTransactionsManager
    ) {
        pendingExpressTxStatusBottomSheetViewModel = PendingExpressTxStatusBottomSheetViewModel(
            pendingTransaction: pendingTransaction,
            currentTokenItem: tokenItem,
            userWalletModel: userWalletModel,
            pendingTransactionsManager: pendingTransactionsManager,
            router: self
        )
    }
}

// MARK: - OrganizeTokensRoutable protocol conformance

extension MainCoordinator: OrganizeTokensRoutable {
    func didTapCancelButton() {
        organizeTokensViewModel = nil
    }

    func didTapSaveButton() {
        organizeTokensViewModel = nil
    }
}

// MARK: - Visa

extension MainCoordinator: VisaWalletRoutable {
    func openTransactionDetails(tokenItem: TokenItem, for record: VisaTransactionRecord, emailConfig: EmailConfig) {
        visaTransactionDetailsViewModel = .init(tokenItem: tokenItem, transaction: record, emailConfig: emailConfig, router: self)
    }
}

extension MainCoordinator: VisaTransactionDetailsRouter {}

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

        coordinator.start(
            with: .default(
                options: .init(
                    userWalletModel: userWalletModel,
                    expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletModel: userWalletModel),
                    tokenSorter: CommonBuyTokenAvailabilitySorter()
                )
            )
        )

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
                self?.openSendToSell(
                    amountToSend: model.amountToSend,
                    destination: model.destination,
                    tag: model.tag,
                    userWalletModel: userWalletModel,
                    walletModel: model.walletModel
                )
            }
        )

        coordinator.start(with: .default)
        actionButtonsSellCoordinator = coordinator
    }
}

// MARK: - ActionButtonsSwapFlowRoutable

extension MainCoordinator: ActionButtonsSwapFlowRoutable {
    func openSwap(userWalletModel: some UserWalletModel) {
        let coordinator = coordinatorFactory.makeSwapCoordinator(userWalletModel: userWalletModel) { [weak self] _ in
            self?.actionButtonsSwapCoordinator = nil
        }

        let openExpressBlock = { [weak self] in
            guard let self else { return }
            coordinator.start(with: .default)
            actionButtonsSwapCoordinator = coordinator
        }

        Task { @MainActor [tangemStoriesPresenter] in
            tangemStoriesPresenter.present(
                story: .swap(.initialWithoutImages),
                analyticsSource: .main,
                presentCompletion: openExpressBlock
            )
        }
    }
}

// MARK: - PendingExpressTxStatusRoutable

extension MainCoordinator: PendingExpressTxStatusRoutable {
    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func openCurrency(tokenItem: TokenItem, userWalletModel: UserWalletModel) {
        pendingExpressTxStatusBottomSheetViewModel = nil

        // We don't have info about derivation here, so we have to find first non-custom walletModel.
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem.blockchain == tokenItem.blockchain
                && $0.tokenItem.token == tokenItem.token
                && !$0.isCustom
        }) else {
            return
        }

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

// MARK: - NFTEntrypointRoutable

extension MainCoordinator: NFTEntrypointRoutable {
    func openCollections(nftManager: NFTManager, navigationContext: NFTNavigationContext) {
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

        nftCollectionsCoordinator = coordinator
        coordinator.start(
            with: .init(
                nftManager: nftManager,
                nftChainIconProvider: NetworkImageProvider(),
                nftChainNameProvider: NFTChainNameProvider(),
                priceFormatter: NFTPriceFormatter(),
                navigationContext: navigationContext,
                blockchainSelectionAnalytics: NFTAnalytics.BlockchainSelection(
                    logBlockchainChosen: { blockchain in
                        Analytics.log(event: .nftReceiveBlockchainChosen, params: [.blockchain: blockchain])
                    }
                )
            )
        )
    }
}

// MARK: - WCTransactionRoutable

extension MainCoordinator: WCTransactionRoutable {
    func showWCTransactionRequest(with data: WCHandleTransactionData) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: WCTransactionViewModel(
                    dappData: data.dAppData,
                    transactionData: data,
                    analyticsLogger: CommonWalletConnectTransactionAnalyticsLogger()
                )
            )
        }
    }

    func showWCTransactionRequest(with error: Error) {
        // make error view model
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
    }
}

// MARK: - HotFinishActivationNeededRoutable

extension MainCoordinator: HotFinishActivationNeededRoutable {
    func dismissHotFinishActivationNeeded() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openHotBackupOnboarding(userWalletModel: UserWalletModel) {
        let backupInput = HotOnboardingInput(flow: .walletActivate(userWalletModel: userWalletModel))
        openOnboardingModal(with: .hotInput(backupInput))
    }
}
