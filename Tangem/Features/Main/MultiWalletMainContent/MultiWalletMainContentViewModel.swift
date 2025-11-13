//
//  MultiWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import TangemFoundation
import TangemStaking
import TangemNFT
import TangemLocalization
import TangemUI
import TangemMobileWalletSdk
import struct TangemUIUtils.AlertBinder
import TangemVisa
import BlockchainSdk

final class MultiWalletMainContentViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isLoadingTokenList: Bool = true
    @Published var notificationInputs: [NotificationViewInput] = []
    @Published var tokensNotificationInputs: [NotificationViewInput] = []
    @Published var bannerNotificationInputs: [NotificationViewInput] = []
    @Published var yieldModuleNotificationInputs: [NotificationViewInput] = []

    @Published var accountSections: [MultiWalletMainContentAccountSection] = []
    @Published var plainSections: [MultiWalletMainContentPlainSection] = []

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    @Published var tangemPayNotificationInputs: [NotificationViewInput] = []
    @Published var tangemPayCardIssuingInProgress: Bool = false

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    @Published var tangemPayAccountViewModel: TangemPayAccountViewModel?

    @Published var isScannerBusy = false
    @Published var error: AlertBinder? = nil
    @Published var nftEntrypointViewModel: NFTEntrypointViewModel?

    weak var delegate: MultiWalletMainContentDelegate?

    var footerViewModel: MainFooterViewModel?

    private(set) lazy var bottomSheetFooterViewModel = MainBottomSheetFooterViewModel()

    @Published private(set) var actionButtonsViewModel: ActionButtonsViewModel?

    // [REDACTED_TODO_COMMENT]
    var isOrganizeTokensVisible: Bool {
        guard canManageTokens else { return false }

        if plainSections.isEmpty {
            return false
        }

        let numberOfTokens = plainSections.reduce(0) { $0 + $1.items.count }
        let requiredNumberOfTokens = 2

        return numberOfTokens >= requiredNumberOfTokens
    }

    // MARK: - Dependencies

    @Injected(\.mobileFinishActivationManager) private var mobileFinishActivationManager: MobileFinishActivationManager

    private let nftFeatureLifecycleHandler: NFTFeatureLifecycleHandling
    private let userWalletModel: UserWalletModel
    private let userWalletNotificationManager: NotificationManager
    private let sectionsProvider: any MultiWalletMainContentViewSectionsProvider
    private let tokensNotificationManager: NotificationManager
    private let bannerNotificationManager: NotificationManager?
    private let tokenRouter: SingleTokenRoutable
    private let rateAppController: RateAppInteractionController
    private let balanceRestrictionFeatureAvailabilityProvider: BalanceRestrictionFeatureAvailabilityProvider
    private weak var coordinator: (MultiWalletMainContentRoutable & ActionButtonsRoutable & NFTEntrypointRoutable)?

    private var canManageTokens: Bool { userWalletModel.config.hasFeature(.multiCurrency) }

    private let isPageSelectedSubject = PassthroughSubject<Bool, Never>()
    private var isUpdating = false

    private var bag = Set<AnyCancellable>()

    init(
        userWalletModel: UserWalletModel,
        userWalletNotificationManager: NotificationManager,
        sectionsProvider: any MultiWalletMainContentViewSectionsProvider,
        tokensNotificationManager: NotificationManager,
        bannerNotificationManager: NotificationManager?,
        rateAppController: RateAppInteractionController,
        nftFeatureLifecycleHandler: NFTFeatureLifecycleHandling,
        tokenRouter: SingleTokenRoutable,
        coordinator: (MultiWalletMainContentRoutable & ActionButtonsRoutable & NFTEntrypointRoutable)?
    ) {
        self.userWalletModel = userWalletModel
        self.userWalletNotificationManager = userWalletNotificationManager
        self.sectionsProvider = sectionsProvider
        self.tokensNotificationManager = tokensNotificationManager
        self.bannerNotificationManager = bannerNotificationManager
        self.rateAppController = rateAppController
        self.tokenRouter = tokenRouter
        self.coordinator = coordinator
        self.nftFeatureLifecycleHandler = nftFeatureLifecycleHandler

        balanceRestrictionFeatureAvailabilityProvider = BalanceRestrictionFeatureAvailabilityProvider(
            userWalletConfig: userWalletModel.config,
            totalBalanceProvider: userWalletModel
        )

        sectionsProvider.setup(with: self)

        bind()

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
        if FeatureProvider.isAvailable(.visa) {
            userWalletModel.tangemPayAccountPublisher
                .flatMapLatest(\.tangemPayNotificationManager.notificationPublisher)
                .receiveOnMain()
                .assign(to: \.tangemPayNotificationInputs, on: self, ownership: .weak)
                .store(in: &bag)

            userWalletModel.tangemPayAccountPublisher
                .flatMapLatest(\.tangemPayCardIssuingInProgressPublisher)
                .receiveOnMain()
                .assign(to: \.tangemPayCardIssuingInProgress, on: self, ownership: .weak)
                .store(in: &bag)

            userWalletModel.tangemPayAccountPublisher
                .withWeakCaptureOf(self)
                .flatMapLatest { viewModel, tangemPayAccount in
                    tangemPayAccount.tangemPayCardDetailsPublisher
                        .withWeakCaptureOf(viewModel)
                        .map { viewModel, cardDetails in
                            guard let (card, balance) = cardDetails else {
                                return nil
                            }
                            return TangemPayAccountViewModel(
                                card: card,
                                balance: balance,
                                tapAction: {
                                    viewModel.openTangemPayMainView(
                                        tangemPayAccount: tangemPayAccount,
                                        cardNumberEnd: card.cardNumberEnd
                                    )
                                }
                            )
                        }
                }
                .receiveOnMain()
                .assign(to: \.tangemPayAccountViewModel, on: self, ownership: .weak)
                .store(in: &bag)
        }
    }

    deinit {
        AppLogger.debug("\(userWalletModel.name) deinit")
    }

    func onPullToRefresh() async {
        if isUpdating {
            return
        }

        isUpdating = true
        refreshActionButtonsData()

        await withTaskGroup { group in
            group.addTask {
                await withCheckedContinuation { [weak self] checkedContinuation in
                    // accounts_fixes_needed_main
                    self?.userWalletModel.userTokensManager.sync { [weak self] in
                        self?.isUpdating = false
                        checkedContinuation.resume()
                    }
                }
            }

            // [REDACTED_TODO_COMMENT]
            // [REDACTED_INFO]
            if FeatureProvider.isAvailable(.visa), let tangemPayAccount = userWalletModel.tangemPayAccount {
                group.addTask {
                    await tangemPayAccount.loadCustomerInfo().value
                }
            }

            await group.waitForAll()
        }
    }

    func onFirstAppear() {
        finishMobileActivationIfNeeded()
    }

    func finishMobileActivationIfNeeded() {
        mobileFinishActivationManager.activateIfNeeded(userWalletModel: userWalletModel)
    }

    func deriveEntriesWithoutDerivation() {
        Analytics.log(.mainNoticeScanYourCardTapped)
        isScannerBusy = true
        // accounts_fixes_needed_main
        userWalletModel.userTokensManager.deriveIfNeeded { [weak self] _ in
            DispatchQueue.main.async {
                self?.isScannerBusy = false
            }
        }
    }

    func startBackupProcess() {
        if let input = userWalletModel.backupInput {
            Analytics.log(.mainNoticeBackupWalletTapped)
            coordinator?.openOnboardingModal(with: .input(input))
        }
    }

    func onOpenOrganizeTokensButtonTap() {
        openOrganizeTokens()
    }

    private func refreshActionButtonsData() {
        actionButtonsViewModel?.refresh()
    }

    private func bind() {
        let walletsWithNFTEnabledPublisher = nftFeatureLifecycleHandler
            .walletsWithNFTEnabledPublisher
            .share(replay: 1)

        // accounts_fixes_needed_nft
        let nftEntrypointViewModelPublisher = Publishers.Merge(
            walletsWithNFTEnabledPublisher,
            userWalletModel
                .walletModelsManager
                .walletModelsPublisher
                .withLatestFrom(walletsWithNFTEnabledPublisher)
        )

        nftEntrypointViewModelPublisher
            .withWeakCaptureOf(self)
            .flatMap { viewModel, walletsWithNFTEnabled in
                let isNFTEnabledForWallet = walletsWithNFTEnabled.contains(viewModel.userWalletModel.userWalletId)
                let result = Result { try viewModel.makeNFTEntrypointViewModelIfNeeded(isNFTEnabledForWallet: isNFTEnabledForWallet) }

                return result
                    .publisher
                    .materialize()
            }
            .values()
            .receiveOnMain()
            .assign(to: \.nftEntrypointViewModel, on: self, ownership: .weak)
            .store(in: &bag)

        let plainSectionsPublisher = sectionsProvider.makePlainSectionsPublisher()
        plainSectionsPublisher
            .eraseToAnyPublisher()
            .receiveOnMain()
            .assign(to: \.plainSections, on: self, ownership: .weak)
            .store(in: &bag)

        let accountSectionsPublisher = sectionsProvider.makeAccountSectionsPublisher()
        accountSectionsPublisher
            .eraseToAnyPublisher()
            .receiveOnMain()
            .assign(to: \.accountSections, on: self, ownership: .weak)
            .store(in: &bag)

        // [REDACTED_TODO_COMMENT]
        subscribeToTokenListSync(with: plainSectionsPublisher)

        userWalletNotificationManager
            .notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        tokensNotificationManager
            .notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.tokensNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        bannerNotificationManager?
            .notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.bannerNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        rateAppController.bind(
            isPageSelectedPublisher: isPageSelectedSubject,
            notificationsPublisher1: $notificationInputs,
            notificationsPublisher2: $tokensNotificationInputs
        )

        balanceRestrictionFeatureAvailabilityProvider.isActionButtonsAvailablePublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isAvailable in
                viewModel.actionButtonsViewModel = isAvailable ? viewModel.makeActionButtonsViewModel() : nil
            }
            .store(in: &bag)

        nftFeatureLifecycleHandler.startObserving()
    }

    /// - Note: This method throws an opaque error if the NFT Entrypoint view model is already created and there is no need to update it.
    private func makeNFTEntrypointViewModelIfNeeded(isNFTEnabledForWallet: Bool) throws -> NFTEntrypointViewModel? {
        // NFT Entrypoint is shown only if the feature is enabled for the wallet and there is at least one token in the token list
        // accounts_fixes_needed_nft
        guard isNFTEnabledForWallet, userWalletModel.walletModelsManager.walletModels.isNotEmpty else {
            return nil
        }

        // Early exit when the NFT Entrypoint view model has already been created, since there is no point in creating it again
        if nftEntrypointViewModel != nil {
            throw "NFTEntrypointViewModel already created"
        }

        // accounts_fixes_needed_nft
        let navigationContext = NFTNavigationInput(
            userWalletModel: userWalletModel,
            name: userWalletModel.name,
            walletModelsManager: userWalletModel.walletModelsManager
        )
        let accountForNFTCollectionsProvider = AccountForNFTCollectionProvider(
            accountModelsManager: userWalletModel.accountModelsManager
        )
        let nftAccountNavigationContextProvider = NFTAccountNavigationContextProvider(
            userWalletModel: userWalletModel
        )

        return NFTEntrypointViewModel(
            nftManager: userWalletModel.nftManager,
            accountForCollectionsProvider: accountForNFTCollectionsProvider,
            nftAccountNavigationContextProvider: nftAccountNavigationContextProvider,
            navigationContext: navigationContext,
            analytics: NFTAnalytics.Entrypoint(
                logCollectionsOpen: { state, collectionsCount, nftsCount, dummyCollectionsCount in
                    Analytics.log(
                        event: .nftCollectionsOpened,
                        params: [
                            .state: state,
                            .nftCollectionsCount: "\(collectionsCount)",
                            .nftAssetsCount: "\(nftsCount)",
                            .nftDummyCollectionsCount: "\(dummyCollectionsCount)",
                        ]
                    )
                }
            ),
            coordinator: coordinator
        )
    }

    private func subscribeToTokenListSync(with sectionsPublisher: some Publisher<[MultiWalletMainContentPlainSection], Never>) {
        // accounts_fixes_needed_main
        let tokenListSyncPublisher = userWalletModel
            .userTokensManager
            .initializedPublisher
            .filter { $0 }

        let sectionsPublisher = sectionsPublisher
            .replaceEmpty(with: [])

        var tokenListSyncSubscription: AnyCancellable?
        tokenListSyncSubscription = Publishers.Zip(tokenListSyncPublisher, sectionsPublisher)
            .prefix(1)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.isLoadingTokenList = false
                withExtendedLifetime(tokenListSyncSubscription) {}
            }
    }

    func makeApyBadgeTapAction(for walletModelId: WalletModelId) -> ((WalletModelId) -> Void)? {
        // accounts_fixes_needed_yield
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id.id == walletModelId.id }),
              TokenActionAvailabilityProvider(userWalletConfig: userWalletModel.config, walletModel: walletModel).isTokenInteractionAvailable()
        else {
            return nil
        }

        if let stakingManager = walletModel.stakingManager {
            return { [weak self] _ in
                self?.handleStakingApyBadgeTapped(walletModel: walletModel, stakingManager: stakingManager)
            }
        } else if
            let yieldModuleManager = walletModel.yieldModuleManager,
            let factory = makeYieldModuleFlowFactory(walletModel: walletModel, manager: yieldModuleManager) {
            return { [weak self] _ in
                self?.handleYieldApyBadgeTapped(
                    walletModel: walletModel,
                    yieldManager: yieldModuleManager,
                    yieldModuleFactory: factory
                )
            }
        } else {
            return nil
        }
    }

    private func handleYieldApyBadgeTapped(
        walletModel: any WalletModel,
        yieldManager: YieldModuleManager,
        yieldModuleFactory: YieldModuleFlowFactory
    ) {
        let logger = CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem)

        switch yieldManager.state?.state {
        case .active:
            logger.logEarningApyClicked(state: .enabled)
            coordinator?.openYieldModuleActiveInfo(factory: yieldModuleFactory)
        case .processing:
            coordinator?.openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
        case .notActive:
            if let apy = yieldManager.state?.marketInfo?.apy {
                logger.logEarningApyClicked(state: .disabled)
                coordinator?.openYieldModulePromoView(apy: apy, factory: yieldModuleFactory)
            }
        case .disabled, .failedToLoad, .loading, .none:
            break
        }
    }

    private func handleStakingApyBadgeTapped(walletModel: any WalletModel, stakingManager: StakingManager) {
        let analyticsState: String

        switch stakingManager.state {
        case .availableToStake:
            analyticsState = Analytics.ParameterValue.disabled.rawValue
        case .staked:
            analyticsState = Analytics.ParameterValue.enabled.rawValue
        case .loading, .loadingError, .temporaryUnavailable, .notEnabled:
            return
        }

        logStakingApyClicked(
            state: analyticsState,
            tokenName: SendAnalyticsHelper.makeAnalyticsTokenName(from: walletModel.tokenItem),
            blockchainName: walletModel.tokenItem.blockchain.displayName
        )

        coordinator?.openStaking(
            options: .init(
                sendInput: SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel),
                manager: stakingManager
            )
        )
    }

    private func tokenItemTapped(_ walletModelId: WalletModelId) {
        guard
            let walletModel = findWalletModel(with: walletModelId),
            TokenActionAvailabilityProvider(userWalletConfig: userWalletModel.config, walletModel: walletModel).isTokenInteractionAvailable()
        else {
            return
        }

        coordinator?.openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
    }

    private func openTangemPayMainView(tangemPayAccount: TangemPayAccount, cardNumberEnd: String) {
        coordinator?.openTangemPayMainView(
            userWalletInfo: userWalletModel.userWalletInfo,
            tangemPayAccount: tangemPayAccount,
            cardNumberEnd: cardNumberEnd
        )
    }

    private func makeYieldModuleFlowFactory(walletModel: any WalletModel, manager: YieldModuleManager) -> YieldModuleFlowFactory? {
        guard let dispatcher = TransactionDispatcherFactory(
            walletModel: walletModel, signer: userWalletModel.signer
        ).makeYieldModuleDispatcher() else {
            return nil
        }

        return CommonYieldModuleFlowFactory(
            walletModel: walletModel,
            yieldModuleManager: manager,
            transactionDispatcher: dispatcher
        )
    }

    private func findWalletModel(with id: WalletModelId) -> (any WalletModel)? {
        // accounts_fixes_needed_token_none
        let allWalletModels = FeatureProvider.isAvailable(.accounts)
            ? AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
            : userWalletModel.walletModelsManager.walletModels

        return allWalletModels.first(where: { $0.id.id == id.id })
    }
}

// MARK: Hide token

private extension MultiWalletMainContentViewModel {
    func hideTokenAction(for tokenItemViewModel: TokenItemViewModel) {
        let tokenItem = tokenItemViewModel.tokenItem

        let alertBuilder = HideTokenAlertBuilder()
        // accounts_fixes_needed_main
        if userWalletModel.userTokensManager.canRemove(tokenItem) {
            error = alertBuilder.hideTokenAlert(tokenItem: tokenItem, hideAction: {
                [weak self] in
                self?.hideToken(tokenItem: tokenItem)
            })
        } else {
            error = alertBuilder.unableToHideTokenAlert(tokenItem: tokenItem)
        }
    }

    func hideToken(tokenItem: TokenItem) {
        // accounts_fixes_needed_main
        userWalletModel.userTokensManager.remove(tokenItem)

        Analytics.log(
            event: .buttonRemoveToken,
            params: [
                Analytics.ParameterKey.token: tokenItem.currencySymbol,
                Analytics.ParameterKey.source: Analytics.ParameterValue.main.rawValue,
            ]
        )
    }
}

// MARK: Navigation

extension MultiWalletMainContentViewModel {
    private func openURL(_ url: URL) {
        coordinator?.openInSafari(url: url)
    }

    private func openOrganizeTokens() {
        coordinator?.openOrganizeTokens(for: userWalletModel)
    }

    private func openSupport() {
        Analytics.log(.requestSupport, params: [.source: .main])

        // accounts_fixes_needed_none
        let dataCollector = DetailsFeedbackDataCollector(
            data: [
                .init(
                    userWalletEmailData: userWalletModel.emailData,
                    walletModels: AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)
                ),
            ]
        )

        coordinator?.openMail(
            with: dataCollector,
            emailType: .appFeedback(subject: EmailConfig.default.subject),
            recipient: EmailConfig.default.recipient
        )
    }

    private func openSell(for walletModel: any WalletModel) {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        tokenRouter.openSell(for: walletModel)
    }

    private func openMobileFinishActivation() {
        Analytics.log(.mainButtonFinishNow)
        coordinator?.openMobileBackupOnboarding(userWalletModel: userWalletModel)
    }

    private func openMobileUpgrade() {
        runTask(in: self) { viewModel in
            do {
                let context = try await viewModel.unlock()
                viewModel.coordinator?.openMobileUpgrade(userWalletModel: viewModel.userWalletModel, context: context)
            } catch where error.isCancellationError {
                AppLogger.error("Unlock is canceled", error: error)
            } catch {
                AppLogger.error("Unlock failed:", error: error)
                await runOnMain {
                    viewModel.error = error.alertBinder
                }
            }
        }
    }
}

// MARK: - MultiWalletMainContentItemViewModelFactory protocol conformance

extension MultiWalletMainContentViewModel: MultiWalletMainContentItemViewModelFactory {
    func makeTokenItemViewModel(
        from sectionItem: TokenSectionsAdapter.SectionItem,
        using factory: MultiWalletTokenItemsSectionFactory
    ) -> TokenItemViewModel {
        return factory.makeSectionItemViewModel(
            from: sectionItem,
            contextActionsProvider: self,
            contextActionsDelegate: self,
            tapAction: weakify(self, forFunction: MultiWalletMainContentViewModel.tokenItemTapped(_:)),
            yieldApyTapAction: { [weak self] id in
                let action = self?.makeApyBadgeTapAction(for: id)
                action?(id)
            }
        )
    }
}

// MARK: - NotificationTapDelegate protocol conformance

extension MultiWalletMainContentViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .empty:
            guard let notification = notificationInputs.first(where: { $0.id == id }) else {
                userWalletNotificationManager.dismissNotification(with: id)
                return
            }

            switch notification.settings.event {
            case let userWalletEvent as GeneralNotificationEvent:
                handleUserWalletNotificationTap(event: userWalletEvent, id: id)
            default:
                break
            }
        case .generateAddresses:
            deriveEntriesWithoutDerivation()
        case .backupCard:
            startBackupProcess()
        case .openLink(let url, _):
            openURL(url)
        case .openFeedbackMail:
            rateAppController.openFeedbackMail()
        case .openAppStoreReview:
            rateAppController.openAppStoreReview()
        case .support:
            openSupport()
        case .seedSupportYes, .seedSupport2Yes:
            error = AlertBuilder.makeSeedNotifyAlert(message: Localization.warningSeedphraseIssueAnswerYes) { [weak self] in
                self?.openURL(TangemBlogUrlBuilder().url(post: .seedNotify))
                self?.userWalletNotificationManager.dismissNotification(with: id)
            }
        case .seedSupportNo:
            error = AlertBuilder.makeSeedNotifyAlert(message: Localization.warningSeedphraseIssueAnswerNo) { [weak self] in
                self?.userWalletNotificationManager.dismissNotification(with: id)
            }
        case .seedSupport2No:
            userWalletNotificationManager.dismissNotification(with: id)
        case .openMobileFinishActivation:
            openMobileFinishActivation()
        case .openMobileUpgrade:
            openMobileUpgrade()
        case .openBuyCrypto(let walletModel, let parameters):
            let input = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)
            coordinator?.openOnramp(input: input, parameters: parameters)
        case .allowPushPermissionRequest, .postponePushPermissionRequest:
            userWalletNotificationManager.dismissNotification(with: id)
        default:
            break
        }
    }

    private func handleUserWalletNotificationTap(event: GeneralNotificationEvent, id: NotificationViewId) {
        switch event {
        default:
            assertionFailure("This event shouldn't have tap action on main screen. Event: \(event)")
        }
    }
}

// MARK: - MainViewPage protocol conformance

extension MultiWalletMainContentViewModel: MainViewPage {
    func onPageAppear() {
        isPageSelectedSubject.send(true)
    }

    func onPageDisappear() {
        isPageSelectedSubject.send(false)
    }
}

// MARK: - TokenItemContextActionsProvider protocol conformance

extension MultiWalletMainContentViewModel: TokenItemContextActionsProvider {
    func buildContextActions(for tokenItemViewModel: TokenItemViewModel) -> [TokenContextActionsSection] {
        let actionBuilder = TokenContextActionsSectionBuilder()
        let walletModel = findWalletModel(with: tokenItemViewModel.id)

        return actionBuilder.buildContextActionsSections(
            tokenItem: tokenItemViewModel.tokenItem,
            walletModel: walletModel,
            userWalletConfig: userWalletModel.config,
            canNavigateToMarketsDetails: true,
            canHideToken: canManageTokens
        )
    }
}

// MARK: - TokenItemContextActionDelegate protocol conformance

extension MultiWalletMainContentViewModel: TokenItemContextActionDelegate {
    func didTapContextAction(_ action: TokenActionType, for tokenItemViewModel: TokenItemViewModel) {
        switch action {
        case .hide:
            hideTokenAction(for: tokenItemViewModel)
            return
        case .marketsDetails:
            logContextTap(action: action, for: tokenItemViewModel)
            tokenRouter.openMarketsTokenDetails(for: tokenItemViewModel.tokenItem)
            return
        default:
            break
        }

        guard
            let walletModel = findWalletModel(with: tokenItemViewModel.id)
        else {
            return
        }

        switch action {
        case .buy:
            tokenRouter.openOnramp(walletModel: walletModel)
        case .send:
            tokenRouter.openSend(walletModel: walletModel)
        case .receive:
            tokenRouter.openReceive(walletModel: walletModel)
        case .sell:
            openSell(for: walletModel)
        case .copyAddress:
            logContextTap(action: action, for: tokenItemViewModel)
            UIPasteboard.general.string = walletModel.defaultAddressString
            delegate?.displayAddressCopiedToast()
        case .exchange:
            tokenRouter.openExchange(walletModel: walletModel)
        case .stake:
            tokenRouter.openStaking(walletModel: walletModel)
        case .marketsDetails, .hide:
            return
        }
    }

    func logContextTap(action: TokenActionType, for tokenItemViewModel: TokenItemViewModel) {
        let tokenItem = tokenItemViewModel.tokenItem
        let event: Analytics.Event

        var analyticsParams: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol.uppercased(),
            .blockchain: tokenItem.blockchain.displayName,
        ]

        switch action {
        case .marketsDetails:
            analyticsParams[.source] = Analytics.ParameterValue.longTap.rawValue
            event = .marketsChartScreenOpened
        case .copyAddress:
            analyticsParams[.source] = Analytics.ParameterValue.main.rawValue
            event = .buttonCopyAddress
        default:
            return
        }

        Analytics.log(event: event, params: analyticsParams)
    }
}

// MARK: - Action buttons

private extension MultiWalletMainContentViewModel {
    func makeActionButtonsViewModel() -> ActionButtonsViewModel? {
        guard let coordinator, canManageTokens else { return nil }

        return .init(
            coordinator: coordinator,
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletId: userWalletModel.userWalletId),
            userWalletModel: userWalletModel
        )
    }
}

// MARK: - Unlocking

private extension MultiWalletMainContentViewModel {
    func unlock() async throws -> MobileWalletContext {
        let authUtil = MobileAuthUtil(
            userWalletId: userWalletModel.userWalletId,
            config: userWalletModel.config,
            biometricsProvider: CommonUserWalletBiometricsProvider()
        )

        let result = try await authUtil.unlock()

        switch result {
        case .successful(let context):
            return context

        case .canceled:
            throw CancellationError()

        case .userWalletNeedsToDelete:
            throw CancellationError()
        }
    }
}

// MARK: - Analytics

private extension MultiWalletMainContentViewModel {
    func logStakingApyClicked(state: String, tokenName: String, blockchainName: String) {
        let stateParamValue = Analytics.ParameterValue(rawValue: state)?.rawValue ?? ""
        let actionParamValue = Analytics.ParameterValue.transactionSourceStaking.rawValue

        let params: [Analytics.ParameterKey: String] = [
            .token: tokenName,
            .blockchain: blockchainName,
            .state: stateParamValue,
            .action: actionParamValue,
        ]

        Analytics.log(event: .apyClicked, params: params)
    }
}
