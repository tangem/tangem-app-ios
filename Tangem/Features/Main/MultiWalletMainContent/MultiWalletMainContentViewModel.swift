//
//  MultiWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import class UIKit.UIPasteboard
import CombineExt
import TangemFoundation
import TangemNFT
import TangemLocalization
import TangemUI
import TangemMobileWalletSdk
import TangemVisa
import BlockchainSdk
import struct TangemUIUtils.AlertBinder
import TangemPay

final class MultiWalletMainContentViewModel: ObservableObject {
    // MARK: - ViewState

    @Published private(set) var isLoadingTokenList: Bool = true
    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var tokensNotificationInputs: [NotificationViewInput] = []

    @Published private(set) var accountSections: [MultiWalletMainContentAccountSection] = []
    @Published private(set) var plainSections: [MultiWalletMainContentPlainSection] = []

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    @Published private(set) var tangemPayNotificationInputs: [NotificationViewInput] = []

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    @Published private(set) var tangemPayAccountViewModel: TangemPayAccountViewModel?
    @Published private(set) var polymarketAccountViewModel: AccountRowButtonViewModel?
    @Published private(set) var collectiblesAccountViewModel: AccountRowButtonViewModel?

    @Published private(set) var pendingJointAccountViewModels: [PendingJointAccountItemViewModel] = []
    @Published private(set) var pendingJointAccountsOperationsViewData: [JointAccountOperationPlate.ViewData] = []

    @Published private(set) var isScannerBusy = false
    @Published var error: AlertBinder? = nil
    @Published private(set) var nftEntrypointViewModel: NFTEntrypointViewModel?

    @Published private(set) var tokenItemPromoBubbleViewModel: TokenItemPromoBubbleViewModel?

    let mainNotificationsViewModel: MainNotificationsViewModel

    weak var delegate: MultiWalletMainContentDelegate?

    @Published private(set) var actionButtonsViewModel: ActionButtonsViewModel?

    var isOrganizeTokensVisible: Bool {
        func numberOfTokensInSections<T, U>(_ sections: [SectionModel<T, U>]) -> Int {
            return sections.reduce(0) { $0 + $1.items.count }
        }

        guard canManageTokens else { return false }

        let numberOfTokensInPlainSections = numberOfTokensInSections(plainSections)
        let maxNumberOfTokensInAccountSections = accountSections.map { numberOfTokensInSections($0.items) }.max() ?? 0
        let minRequiredNumberOfTokens = 2

        return numberOfTokensInPlainSections >= minRequiredNumberOfTokens || maxNumberOfTokensInAccountSections >= minRequiredNumberOfTokens
    }

    var organizeTokensButtonTitle: String {
        Localization.mainAddAndManageTokens
    }

    // MARK: - Dependencies

    @Injected(\.mobileFinishActivationManager) private var mobileFinishActivationManager: MobileFinishActivationManager
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let nftFeatureLifecycleHandler: NFTFeatureLifecycleHandling
    private let userWalletModel: UserWalletModel
    private let userWalletNotificationManager: NotificationManager
    private let sectionsProvider: any MultiWalletMainContentViewSectionsProvider
    private let tokensNotificationManager: NotificationManager
    private let promotionNotificationsManager: PromotionNotificationsManager
    private let tangemPayNotificationManager: NotificationManager
    private let forceUpdateBannerNotificationManager: NotificationManager
    private let yieldApyBoostBannerNotificationManager: YieldAPYBoostBannerService
    private let tokenRouter: SingleTokenRoutable
    private let rateAppController: RateAppInteractionController
    private let balanceRestrictionFeatureAvailabilityProvider: BalanceRestrictionFeatureAvailabilityProvider
    private weak var coordinator: (MultiWalletMainContentRoutable & ActionButtonsRoutable & NFTEntrypointRoutable & TokensManagementFlowRoutable)?
    private let tokenItemPromoProvider: TokenItemPromoProvider
    private let expressBalanceUpdater: any ExpressTransactionBalanceUpdater = CommonExpressTransactionBalanceUpdater()

    private lazy var authUtil = MobileAuthUtil(
        userWalletId: userWalletModel.userWalletId,
        config: userWalletModel.config,
        biometricsProvider: CommonUserWalletBiometricsProvider()
    )

    private var derivator: TokenEntriesDerivator?

    private var canManageTokens: Bool { userWalletModel.config.hasFeature(.multiCurrency) }

    @MainActor
    private var isUpdating = false

    private var bag = Set<AnyCancellable>()

    init(
        userWalletModel: UserWalletModel,
        userWalletNotificationManager: NotificationManager,
        sectionsProvider: any MultiWalletMainContentViewSectionsProvider,
        tokensNotificationManager: NotificationManager,
        promotionNotificationsManager: PromotionNotificationsManager,
        tangemPayNotificationManager: NotificationManager,
        yieldApyBoostBannerNotificationManager: YieldAPYBoostBannerService,
        forceUpdateBannerNotificationManager: NotificationManager,
        rateAppController: RateAppInteractionController,
        nftFeatureLifecycleHandler: NFTFeatureLifecycleHandling,
        tokenRouter: SingleTokenRoutable,
        coordinator: (MultiWalletMainContentRoutable & ActionButtonsRoutable & NFTEntrypointRoutable & TokensManagementFlowRoutable)?,
        tokenItemPromoProvider: TokenItemPromoProvider,
        mainNotificationsViewModel: MainNotificationsViewModel
    ) {
        self.userWalletModel = userWalletModel
        self.userWalletNotificationManager = userWalletNotificationManager
        self.sectionsProvider = sectionsProvider
        self.tokensNotificationManager = tokensNotificationManager
        self.promotionNotificationsManager = promotionNotificationsManager
        self.tangemPayNotificationManager = tangemPayNotificationManager
        self.yieldApyBoostBannerNotificationManager = yieldApyBoostBannerNotificationManager
        self.forceUpdateBannerNotificationManager = forceUpdateBannerNotificationManager
        self.rateAppController = rateAppController
        self.tokenRouter = tokenRouter
        self.coordinator = coordinator
        self.nftFeatureLifecycleHandler = nftFeatureLifecycleHandler
        self.tokenItemPromoProvider = tokenItemPromoProvider
        self.mainNotificationsViewModel = mainNotificationsViewModel

        balanceRestrictionFeatureAvailabilityProvider = BalanceRestrictionFeatureAvailabilityProvider(
            userWalletConfig: userWalletModel.config,
            walletModelsPublisher: AccountWalletModelsAggregator.walletModelsPublisher(from: userWalletModel.accountModelsManager),
            updatePublisher: userWalletModel.updatePublisher
        )

        sectionsProvider.configure(with: self)
        tangemPayNotificationManager.setupManager(with: self)

        bind()
        setupActionButtons()
        setupTangemPayIfNeeded()
    }

    deinit {
        AppLogger.debug("MultiWalletMainContentViewModel \(userWalletModel.name) deinit")
    }

    func onDidAppear() {
        mobileFinishActivationManager.onMain(
            userWalletModel: userWalletModel,
            isAppeared: true
        )

        yieldApyBoostBannerNotificationManager.refreshFromCache()

        expressBalanceUpdater.updateUnfinishedDestinationBalances(userWalletId: userWalletModel.userWalletId)

        runTask { [userWalletModel] in
            await AccountModelsAggregator(.polymarket).model(from: userWalletModel.accountModelsManager)?.refreshState()
        }
    }

    func onWillDisappear() {
        mobileFinishActivationManager.onMain(
            userWalletModel: userWalletModel,
            isAppeared: false
        )
    }

    func onPullToRefresh() async {
        if await isUpdating {
            return
        }

        await setIsUpdating(true)
        await promotionNotificationsManager.loadPromotions()
        await refreshActionButtonsData()
        await MultiWalletMainContentUpdater.scheduleUpdate(with: userWalletModel)
        await MainActor.run { mainNotificationsViewModel.refresh() }
        await setIsUpdating(false)
    }

    func deriveEntriesWithoutDerivation() {
        Analytics.log(.mainNoticeScanYourCardTapped)

        derivator = TokenEntriesDerivator(
            userWalletModel: userWalletModel,
            onStart: { [weak self] in
                self?.isScannerBusy = true
            },
            onFinish: { [weak self] in
                self?.isScannerBusy = false
                self?.derivator = nil
            },
        )
        derivator?.derive()
    }

    func renewTangemPaySession() {
        guard let tangemPayAccountModel = AccountModelsAggregator(.tangemPay).model(from: userWalletModel.accountModelsManager) else {
            return
        }
        Analytics.log(.mainNoticeScanYourCardTapped)
        isScannerBusy = true
        tangemPayAccountModel.renewSession(
            authorizingInteractor: userWalletModel.tangemPayAuthorizingInteractor,
            completion: { [weak self] authorizationError in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isScannerBusy = false

                    guard let authorizationError,
                          !authorizationError.isUserCancelled,
                          self.userWalletModel.config.hasFeature(.nfcInteraction)
                    else {
                        return
                    }

                    self.error = AlertBinder(
                        title: Localization.commonError,
                        message: authorizationError.serverErrorStatusCode == nil
                            ? Localization.commonUnknownError
                            : Localization.commonServerUnavailable
                    )
                }
            }
        )
    }

    func startBackupProcess() {
        if let input = userWalletModel.backupInput {
            Analytics.log(.mainNoticeBackupWalletTapped)
            coordinator?.openOnboardingModal(with: .input(input))
        }
    }

    func onOpenOrganizeTokensButtonTap() {
        let analyticsLogger = TokensManagementAnalyticsLogger()
        analyticsLogger.logButtonAddAndOrganize()

        let factory = TokensManagementFlowFactory(userWalletModel: userWalletModel, analyticsLogger: analyticsLogger)
        coordinator?.openAddAndManageTokens(factory: factory)
    }

    func onAddTokensTap() {
        guard let mainAccount = AccountModelsAggregator(.crypto).models(from: userWalletModel.accountModelsManager).first(where: { $0.isMainAccount }) else {
            return
        }

        coordinator?.openManageTokens(for: mainAccount, in: userWalletModel)
    }

    @MainActor
    private func setIsUpdating(_ newValue: Bool) {
        isUpdating = newValue
    }

    @MainActor
    private func refreshActionButtonsData() {
        actionButtonsViewModel?.refresh()
    }

    private func bind() {
        let walletsWithNFTEnabledPublisher = nftFeatureLifecycleHandler
            .walletsWithNFTEnabledPublisher
            .share(replay: 1)

        let nftEntrypointViewModelPublisher = AccountWalletModelsAggregator
            .walletModelsPublisher(from: userWalletModel.accountModelsManager)
            .withLatestFrom(walletsWithNFTEnabledPublisher)
            .merge(with: walletsWithNFTEnabledPublisher)

        nftEntrypointViewModelPublisher
            .withWeakCaptureOf(self)
            .flatMap { viewModel, walletsWithNFTEnabled in
                let isNFTEnabledForWallet = walletsWithNFTEnabled.contains(viewModel.userWalletModel.userWalletId)
                let result = Result {
                    try viewModel.makeNFTEntrypointViewModelIfNeeded(isNFTEnabledForWallet: isNFTEnabledForWallet)
                }

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
            .assign(to: \.plainSections, on: self, ownership: .weak)
            .store(in: &bag)

        let accountSectionsPublisher = sectionsProvider.makeAccountSectionsPublisher()
        accountSectionsPublisher
            .assign(to: \.accountSections, on: self, ownership: .weak)
            .store(in: &bag)

        let tokenItemPromoInputPublisher = accountSectionsPublisher
            .eraseToAnyPublisher()
            .combineLatest(plainSectionsPublisher.eraseToAnyPublisher()) { accountSections, plainSections in
                return accountSections.flattenedTokenItems.nilIfEmpty ?? plainSections.flattenedTokenItems
            }
            .mapMany { TokenItemPromoProviderInput(id: $0.id, tokenItem: $0.tokenItem) }

        tokenItemPromoProvider
            .makePromoOutputPublisher(using: tokenItemPromoInputPublisher)
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, output in
                output.map(viewModel.makeTokenItemPromoViewModel(from:))
            }
            .assign(to: \.tokenItemPromoBubbleViewModel, on: self, ownership: .weak)
            .store(in: &bag)

        subscribeToTokenListSync(
            plainSectionsPublisher: plainSectionsPublisher,
            accountSectionsPublisher: accountSectionsPublisher
        )

        // Force-update banner is prepended so it always renders above the wallet notifications.
        forceUpdateBannerNotificationManager
            .notificationPublisher
            .removeDuplicates()
            .combineLatest(userWalletNotificationManager.notificationPublisher.removeDuplicates())
            .map { forceUpdateInputs, userWalletInputs in forceUpdateInputs + userWalletInputs }
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers
            .CombineLatest(
                tokensNotificationManager.notificationPublisher.removeDuplicates(),
                yieldApyBoostBannerNotificationManager.notificationPublisher.removeDuplicates()
            )
            .map { $0 + $1 }
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.tokensNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        bindMainNotificationsVisibility()

        rateAppController.bind(
            notificationsPublisher1: $notificationInputs,
            notificationsPublisher2: $tokensNotificationInputs
        )

        nftFeatureLifecycleHandler.startObserving()

        bindPolymarketAccountRow()
        bindCollectiblesAccountRow()
        bindPendingJointAccountPlates()
        bindPendingJointAccountOperationPlates()
    }

    // MARK: - Main notifications visibility

    private func bindMainNotificationsVisibility() {
        let resolver = MainPromotionalVisibilityResolver()
        let allowedVisibilityPublisher = Publishers
            .CombineLatest3($notificationInputs, $tokensNotificationInputs, $pendingJointAccountsOperationsViewData)
            .map { notifications, tokensNotifications, jointOperations in
                resolver.resolve(
                    systemNotifications: notifications,
                    hasOtherSystemContent: !tokensNotifications.isEmpty || !jointOperations.isEmpty
                )
            }
            .removeDuplicates()
            .eraseToAnyPublisher()

        mainNotificationsViewModel.bindVisibility(
            allowedVisibilityPublisher: allowedVisibilityPublisher,
            balanceProvider: userWalletModel
        )
    }

    private func setupTangemPayIfNeeded() {
        tangemPayNotificationManager
            .notificationPublisher
            .receiveOnMain()
            .assign(to: &$tangemPayNotificationInputs)

        AccountModelsAggregator(.tangemPay)
            .modelPublisher(from: userWalletModel.accountModelsManager)
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, accountModel -> AnyPublisher<TangemPayAccountViewModel?, Never> in
                if let accountModel {
                    accountModel.statePublisher
                        .withWeakCaptureOf(viewModel)
                        .map { [weak accountModel] viewModel, state in
                            TangemPayAccountViewModel(
                                tangemPayLocalState: state,
                                userWalletId: viewModel.userWalletModel.userWalletId,
                                cachedStateStorage: AppSettings.shared,
                                lastKnownTangemPayAccount: accountModel?.lastKnownTangemPayAccount,
                                router: viewModel
                            )
                        }
                        .eraseToAnyPublisher()
                } else {
                    Just(nil).eraseToAnyPublisher()
                }
            }
            .receiveOnMain()
            .assign(to: &$tangemPayAccountViewModel)
    }

    private func setupActionButtons() {
        actionButtonsViewModel = makeActionButtonsViewModel()
    }

    private func bindPolymarketAccountRow() {
        AccountModelsAggregator(.polymarket)
            .modelPublisher(from: userWalletModel.accountModelsManager)
            .flatMapLatest { accountModel -> AnyPublisher<(any PolymarketAccountModel)?, Never> in
                guard let accountModel else { return .just(output: nil) }

                return accountModel
                    .statePublisher
                    .map { $0?.isAccountVisible == true }
                    .removeDuplicates()
                    .map { [weak accountModel] isAccountVisible in isAccountVisible ? accountModel : nil }
                    .eraseToAnyPublisher()
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, accountModel -> AccountRowButtonViewModel? in
                accountModel.map { accountModel in
                    AccountRowButtonViewModel(accountModel: accountModel) { [weak viewModel] in
                        guard let viewModel else { return }

                        viewModel.coordinator?.openPolymarket(userWalletModel: viewModel.userWalletModel)
                    }
                }
            }
            .assign(to: &$polymarketAccountViewModel)
    }

    private func bindCollectiblesAccountRow() {
        AccountModelsAggregator(.collectibles)
            .modelPublisher(from: userWalletModel.accountModelsManager)
            .flatMapLatest { accountModel -> AnyPublisher<(any CollectiblesAccountModel)?, Never> in
                guard let accountModel else { return .just(output: nil) }

                return accountModel
                    .hasAccountPublisher
                    .map { [weak accountModel] hasAccount in hasAccount ? accountModel : nil }
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .map { viewModel, accountModel -> AccountRowButtonViewModel? in
                accountModel.map { accountModel in
                    AccountRowButtonViewModel(accountModel: accountModel) { [weak viewModel] in
                        guard let viewModel else { return }

                        viewModel.coordinator?.openCollectibles(
                            with: .init(destination: .main, userWalletModel: viewModel.userWalletModel, accountModel: accountModel)
                        )
                    }
                }
            }
            .receiveOnMain()
            .assign(to: &$collectiblesAccountViewModel)
    }

    private func bindPendingJointAccountPlates() {
        AccountModelsAggregator(.joint(.pending))
            .modelsPublisher(from: userWalletModel.accountModelsManager)
            .withWeakCaptureOf(self)
            .map { viewModel, pendingJointAccounts in
                pendingJointAccounts.map { pendingJointAccount in
                    PendingJointAccountItemViewModel(jointAccount: pendingJointAccount) { [weak viewModel] in
                        guard let viewModel else {
                            return
                        }

                        viewModel.coordinator?.openJointAccountMembers(jointAccount: pendingJointAccount, userWalletConfig: viewModel.userWalletModel.config)
                    }
                }
            }
            .receiveOnMain()
            .assign(to: &$pendingJointAccountViewModels)
    }

    private func bindPendingJointAccountOperationPlates() {
        AccountModelsAggregator(.joint)
            .modelsPublisher(from: userWalletModel.accountModelsManager)
            .flatMapLatest { jointAccounts -> AnyPublisher<[JointAccountPendingOperation], Never> in
                guard jointAccounts.isNotEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                return jointAccounts
                    .map { $0.jointAccountPendingOperationsProvider.pendingOperationsPublisher }
                    .combineLatest()
                    .map { $0.flattened().filter { $0.operation.status == .awaitingSignatures } }
                    .eraseToAnyPublisher()
            }
            .map { pendingOperations in
                let builder = JointAccountOperationPlateViewDataBuilder()

                return pendingOperations.map { pendingOperation in
                    builder.build(pendingOperation: pendingOperation) { [weak self] in
                        guard let self else { return }

                        coordinator?.openJointAccountOperationDetails(pendingOperation: pendingOperation, userWalletInfo: userWalletModel.userWalletInfo)
                    }
                }
            }
            .receiveOnMain()
            .assign(to: &$pendingJointAccountsOperationsViewData)
    }

    /// - Note: This method throws an opaque error if the NFT Entrypoint view model is already created and there is no need to update it.
    private func makeNFTEntrypointViewModelIfNeeded(isNFTEnabledForWallet: Bool) throws -> NFTEntrypointViewModel? {
        let hasWallets = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager).isNotEmpty

        // NFT Entrypoint is shown only if the feature is enabled for the wallet and there is at least one token in the token list
        guard isNFTEnabledForWallet, hasWallets else {
            return nil
        }

        // Early exit when the NFT Entrypoint view model has already been created, since there is no point in creating it again
        if nftEntrypointViewModel != nil {
            throw "NFTEntrypointViewModel already created"
        }

        let accountForNFTCollectionsProvider = AccountForNFTCollectionsProvider(userWalletModel: userWalletModel)

        // [REDACTED_TODO_COMMENT]
        let navigationInput = NFTNavigationInput(
            userWalletModel: userWalletModel,
            name: userWalletModel.name,
            walletModelsManager: LockedWalletModelsManager() // Not used when accounts are enabled, will be removed in [REDACTED_INFO]
        )

        return NFTEntrypointViewModel(
            nftManager: userWalletModel.nftManager,
            accountForCollectionsProvider: accountForNFTCollectionsProvider,
            navigationContext: navigationInput,
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

    private func subscribeToTokenListSync(
        plainSectionsPublisher: some Publisher<[MultiWalletMainContentPlainSection], Never>,
        accountSectionsPublisher: some Publisher<[MultiWalletMainContentAccountSection], Never>
    ) {
        let didSyncTokenListPublisher = userWalletModel
            .accountModelsManager
            .hasSyncedWithRemotePublisher
            .combineLatest(plainSectionsPublisher, accountSectionsPublisher) { hasSyncedWithRemote, plainSections, accountSections in
                // We disable loading state when the token list is synced with remote or there is at least one token
                // in the sections added offline by the user manually using 'manage tokens' flow after offline onboarding
                hasSyncedWithRemote || (plainSections.flattenedTokenItems.isNotEmpty || accountSections.flattenedTokenItems.isNotEmpty)
            }
            .filter { $0 }
            .mapToVoid()
            .eraseToAnyPublisher()

        didSyncTokenListPublisher
            .prefix(1)
            .mapToValue(false)
            .receiveOnMain()
            .assign(to: &$isLoadingTokenList)
    }

    private func tokenItemTapped(_ walletModelId: WalletModelId) {
        guard
            let walletModel = findWalletModel(with: walletModelId),
            TokenActionAvailabilityProvider(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel).isTokenInteractionAvailable()
        else {
            return
        }

        coordinator?.openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
    }

    private func tokenItemMessageBubbleTapped(_ messageBubble: TokenItemViewModel.MessageBubble) {
        switch messageBubble {
        case .jointOperationAwaitingSignature(let pendingOperation):
            coordinator?.openJointAccountOperationDetails(pendingOperation: pendingOperation, userWalletInfo: userWalletModel.userWalletInfo)
        }
    }

    private func makeYieldApyBadgeTapAction(walletModel: any WalletModel) -> ((TokenItem) -> Void)? {
        guard let yieldManager = walletModel.yieldModuleManager,
              let factory = makeYieldModuleFlowFactory(walletModel: walletModel, manager: yieldManager)
        else {
            return nil
        }

        return { [weak self] _ in
            self?.handleYieldApyBadgeTapped(walletModel: walletModel, factory: factory, yieldManager: yieldManager)
        }
    }

    private func handleYieldApyBadgeTapped(walletModel: any WalletModel, factory: YieldModuleFlowFactory, yieldManager: YieldModuleManager) {
        let logger = CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)

        func openActiveYield() {
            logger.logEarningApyClicked(state: .enabled)
            coordinator?.openYieldModuleActiveInfo(factory: factory)
        }

        func openPromoYield() {
            if let apy = yieldManager.state?.marketInfo?.effectiveApy {
                coordinator?.openYieldModulePromoView(apy: apy, factory: factory)
                logger.logEarningApyClicked(state: .disabled)
            }
        }

        switch yieldManager.state?.state {
        case .active:
            openActiveYield()
        case .failedToLoad(_, let cached?):
            switch cached {
            case .active:
                openActiveYield()
            case .notActive:
                openPromoYield()
            default:
                break
            }
        case .processing:
            coordinator?.openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
        case .notActive:
            openPromoYield()
        case .disabled, .failedToLoad, .loading, .none:
            break
        }
    }

    private func makeYieldModuleFlowFactory(walletModel: any WalletModel, manager: YieldModuleManager) -> YieldModuleFlowFactory? {
        // [REDACTED_USERNAME]. Maintain the previous logic. Do not create factory if `multipleTransactionsSender` not found
        guard walletModel.multipleTransactionsSender != nil else {
            return nil
        }

        let factory = WalletModelTransactionDispatcherProvider(walletModel: walletModel, signer: userWalletModel.signer)
        let dispatcher = factory.makeYieldModuleTransactionDispatcher()

        return CommonYieldModuleFlowFactory(
            walletModel: walletModel,
            userWalletInfo: userWalletModel.userWalletInfo,
            yieldModuleManager: manager,
            transactionDispatcher: dispatcher
        )
    }

    private func makeTokenItemPromoViewModel(from output: TokenItemPromoProviderOutput) -> TokenItemPromoBubbleViewModel {
        TokenItemPromoBubbleViewModel(
            id: output.walletModelId,
            leadingImage: output.icon,
            message: output.message,
            onDismiss: { [weak self] in
                self?.tokenItemPromoProvider.hidePromoBubble()
                self?.tokenItemPromoBubbleViewModel = nil
            },
            onTap: { [weak self] in
                guard let userWalletModel = self?.userWalletModel,
                      let walletModel = AccountWalletModelsAggregator
                      .walletModels(from: userWalletModel.accountModelsManager)
                      .first(where: { model in model.id == output.walletModelId })
                else {
                    return
                }

                let logger = CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: userWalletModel.userWalletId)
                logger.logYieldNoticeClicked()
                let navAction = self?.makeYieldApyBadgeTapAction(walletModel: walletModel)
                navAction?(walletModel.tokenItem)
            },
            onAppear: { [weak self] in
                guard let userWalletId = self?.userWalletModel.userWalletId else {
                    return
                }

                let logger = CommonYieldAnalyticsLogger(tokenItem: output.tokenItem, userWalletId: userWalletId)
                logger.logYieldNoticeShown()
            }
        )
    }

    private func findWalletModel(with id: WalletModelId) -> (any WalletModel)? {
        let allWalletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        return allWalletModels.first(where: { $0.id.id == id.id })
    }
}

// MARK: Hide token

private extension MultiWalletMainContentViewModel {
    func hideTokenAction(for tokenItemViewModel: TokenItemViewModel) {
        let tokenItem = tokenItemViewModel.tokenItem
        let alertBuilder = HideTokenAlertBuilder()
        let actionFactory = HideTokenActionFactory(userWalletModel: userWalletModel)

        do {
            let hideAction = try actionFactory.makeAction(for: tokenItem)
            error = alertBuilder.hideTokenAlert(tokenItem: tokenItem, hideAction: hideAction)
        } catch {
            AppLogger.error("Can't hide token due to error:", error: error)
            self.error = alertBuilder.unableToHideTokenAlert(tokenItem: tokenItem)
        }
    }
}

// MARK: Navigation

extension MultiWalletMainContentViewModel {
    private func openURL(_ url: URL) {
        coordinator?.openInSafari(url: url)
    }

    private func openCloreMigration() {
        guard let walletModel = findCloreWalletModelForMigration() else {
            return
        }

        coordinator?.openCloreMigration(walletModel: walletModel)
    }

    private func openManageTokens() {
        guard let mainAccount = AccountModelsAggregator(.crypto).models(from: userWalletModel.accountModelsManager).first(where: \.isMainAccount) else {
            return
        }

        coordinator?.openManageTokens(for: mainAccount, in: userWalletModel)
    }

    private func openAddFunds() {
        let userWalletModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }
        coordinator?.openBuy(userWalletModels: userWalletModels, preferredWalletId: ActionButtonsBuyPreselection.userWalletId(for: userWalletModel))
    }

    private func openBackupErrorSupport() {
        Analytics.log(.requestSupport, params: [.source: .main])

        let dataCollector = DetailsFeedbackDataCollector(
            data: [
                .init(
                    userWalletEmailData: userWalletModel.emailData,
                    walletModels: AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
                ),
            ]
        )

        coordinator?.openMail(
            with: dataCollector,
            emailType: .appFeedback(subject: EmailConfig.backupError.subject),
            recipient: EmailConfig.backupError.recipient
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
        Analytics.log(.mainButtonFinalizeActivation)

        let isBackupNeeded = MobileBackupStatusUtil(userWalletModel: userWalletModel).isBackupNeeded
        if isBackupNeeded {
            coordinator?.openMobileBackup(userWalletModel: userWalletModel)
        } else {
            runTask(in: self) { viewModel in
                await viewModel.openMobileBackupOnboarding()
            }
        }
    }

    private func openMobileBackupOnboarding() async {
        switch await unlock() {
        case .successful(let context):
            await openMobileOnboarding(context: context)
        case .failed(let error):
            AppLogger.error("Unlock failed:", error: error)
            await showUnlockingErrorAlert(error)
        case .canceled:
            break
        }
    }

    @MainActor
    private func openMobileOnboarding(context: MobileWalletContext) {
        coordinator?.openMobileBackupOnboarding(userWalletModel: userWalletModel, context: context)
    }

    @MainActor
    private func showUnlockingErrorAlert(_ error: Error) {
        self.error = error.alertBinder
    }

    private func openHardwareBackupTypes() {
        logMainButtonUpgradeAnalytics()
        coordinator?.openHardwareBackupTypes(userWalletModel: userWalletModel)
    }

    private func findCloreWalletModelForMigration() -> (any WalletModel)? {
        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        let walletModelWithBalance = walletModels.first {
            $0.tokenItem.blockchain == .clore && ($0.totalTokenBalanceProvider.balanceType.value ?? 0) > 0
        }

        return walletModelWithBalance ?? walletModels.first { $0.tokenItem.blockchain == .clore }
    }
}

// MARK: - TangemPayAccountRoutable

extension MultiWalletMainContentViewModel: TangemPayAccountRoutable {
    func openTangemPayKYCInProgressPopup(tangemPayKYCInteractor: TangemPayKYCInteractor) {
        coordinator?.openTangemPayKYCInProgressPopup(tangemPayKYCInteractor: tangemPayKYCInteractor)
    }

    func openTangemPayKYCDeclinedPopup(tangemPayKYCInteractor: TangemPayKYCInteractor) {
        coordinator?.openTangemPayKYCDeclinedPopup(tangemPayKYCInteractor: tangemPayKYCInteractor)
    }

    func openTangemPayFailedToIssueCardPopup() {
        coordinator?.openTangemPayFailedToIssueCardPopup(userWalletModel: userWalletModel)
    }

    func openTangemPayResidency(interactor: any TangemPayResidencyInteractor) {
        coordinator?.openTangemPayResidency(interactor: interactor)
    }

    func openTangemPayRegionUnavailablePopup(region: TangemPayUnavailableRegion, interactor: any TangemPayResidencyInteractor) {
        coordinator?.openTangemPayRegionUnavailablePopup(region: region, interactor: interactor)
    }

    func openTangemPayMainView(tangemPayAccount: TangemPayAccount) {
        coordinator?.openTangemPayMainView(
            userWalletInfo: userWalletModel.userWalletInfo,
            tangemPayAccount: tangemPayAccount,
            userWalletModel: userWalletModel,
            openingAction: nil
        )
    }

    func openTangemPaySelectPlan(tariffPlanSelector: any TangemPayTariffPlanSelector) {
        coordinator?.openTangemPaySelectPlan(
            tariffPlanSelector: tariffPlanSelector,
            userWalletModel: userWalletModel
        )
    }
}

// MARK: - MultiWalletMainContentItemViewModelFactory protocol conformance

extension MultiWalletMainContentViewModel: MultiWalletMainContentItemViewModelFactory {
    func makeTokenItemViewModel(
        from sectionItem: TokenSectionsAdapter.SectionItem,
        using sectionItemsFactory: MultiWalletSectionItemsFactory
    ) -> TokenItemViewModel {
        return sectionItemsFactory.makeSectionItemViewModel(
            from: sectionItem,
            contextActionsProvider: self,
            contextActionsDelegate: self,
            tapAction: weakify(self, forFunction: MultiWalletMainContentViewModel.tokenItemTapped(_:)),
            messageBubbleTapAction: weakify(self, forFunction: MultiWalletMainContentViewModel.tokenItemMessageBubbleTapped(_:))
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
        case .backupErrorSupport:
            openBackupErrorSupport()
        case .openMobileFinishActivation:
            openMobileFinishActivation()
        case .openMobileUpgrade:
            openHardwareBackupTypes()
        case .allowPushPermissionRequest, .postponePushPermissionRequest:
            userWalletNotificationManager.dismissNotification(with: id)
        case .openCloreMigration:
            openCloreMigration()
        case .openManageTokensAfterWalletSuccessImport:
            openManageTokens()
        case .renewTangemPaySession:
            renewTangemPaySession()
        case .addFunds:
            Analytics.log(.addFundsPromoButton)
            openAddFunds()
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

// MARK: - TokenItemContextActionsProvider protocol conformance

extension MultiWalletMainContentViewModel: TokenItemContextActionsProvider {
    func buildContextActions(for tokenItemViewModel: TokenItemViewModel) -> [TokenContextActionsSection] {
        let actionBuilder = TokenContextActionsSectionBuilder()
        let walletModel = findWalletModel(with: tokenItemViewModel.id)

        return actionBuilder.buildContextActionsSections(
            tokenItem: tokenItemViewModel.tokenItem,
            walletModel: walletModel,
            userWalletInfo: userWalletModel.userWalletInfo,
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

        let availabilityProvider = TokenActionAvailabilityProvider(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)

        switch action {
        case .buy:
            TokenActionAvailabilityAlertPresenter.presentOrProceed(
                handler: &error,
                buyStatus: availabilityProvider.buyAvailablity,
                warning: availabilityProvider.availabilityWarningType,
                action: { [weak self] in
                    self?.tokenRouter.openOnramp(walletModel: walletModel)
                }
            )
        case .send:
            tokenRouter.openSend(walletModel: walletModel)
        case .receive:
            TokenActionAvailabilityAlertPresenter.presentOrProceed(
                handler: &error,
                receiveStatus: availabilityProvider.receiveAvailability,
                warning: availabilityProvider.availabilityWarningType,
                action: { [weak self] in
                    self?.tokenRouter.openReceive(walletModel: walletModel)
                }
            )
        case .sell:
            openSell(for: walletModel)
        case .copyAddress:
            // Unlike Receive / Buy, copying an address isn't a top-up on its own, so the incomplete backup warning doesn't apply.
            TokenActionAvailabilityAlertPresenter.presentOrProceed(
                handler: &error,
                receiveStatus: availabilityProvider.receiveAvailability,
                action: { [weak self] in
                    guard let self else { return }
                    logContextTap(action: action, for: tokenItemViewModel)
                    UIPasteboard.general.string = walletModel.defaultAddressString
                    delegate?.displayAddressCopiedToast()
                }
            )
        case .exchange:
            guard let parameters = SwapPredefinedParametersHelper().makeParameters(
                walletModel: walletModel,
                userWalletInfo: userWalletModel.userWalletInfo,
                position: .automatic
            ) else {
                return
            }

            tokenRouter.openSwap(parameters: parameters)
        case .stake:
            tokenRouter.openStaking(walletModel: walletModel)
        case .yield:
            tokenRouter.openYieldModule(walletModel: walletModel)
        case .marketsDetails, .hide, .swapAndSend:
            return
        }
    }

    func logContextTap(action: TokenActionType, for tokenItemViewModel: TokenItemViewModel) {
        let tokenItem = tokenItemViewModel.tokenItem

        var analyticsParams: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol.uppercased(),
            .blockchain: tokenItem.blockchain.displayName,
        ]

        switch action {
        case .marketsDetails:
            analyticsParams[.source] = Analytics.ParameterValue.longTap.rawValue
            Analytics.log(event: .marketsChartScreenOpened, params: analyticsParams)
        case .copyAddress:
            analyticsParams[.source] = Analytics.ParameterValue.main.rawValue
            Analytics.log(event: .buttonCopyAddress, params: analyticsParams, analyticsSystems: .all)
        default:
            return
        }
    }
}

// MARK: - Action buttons

private extension MultiWalletMainContentViewModel {
    func makeActionButtonsViewModel() -> ActionButtonsViewModel? {
        guard let coordinator else { return nil }

        // Single-token products (e.g. Nodl) can't manage tokens, so the row is pinned via the role flag instead.
        let shouldForceActionButtonsRow = userWalletModel.config.makeActionButtonsRole().forcesActionButtonsRow
            && ActionButtonsVisibility(config: userWalletModel.config).hasVisibleButtons

        guard canManageTokens || shouldForceActionButtonsRow else { return nil }

        return .init(
            coordinator: coordinator,
            userWalletModel: userWalletModel,
            swapAvailabilityChecker: CommonSwapAvailabilityChecker(userWalletInfo: userWalletModel.userWalletInfo)
        )
    }
}

// MARK: - Mobile wallet unlocking

private extension MultiWalletMainContentViewModel {
    func unlock() async -> UnlockResult {
        do {
            let result = try await authUtil.unlock()

            switch result {
            case .successful(let context):
                return .successful(context: context)

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
                return .canceled
            }

        } catch {
            return .failed(error: error)
        }
    }

    enum UnlockResult {
        case successful(context: MobileWalletContext)
        case canceled
        case failed(error: Error)
    }
}

// MARK: - Analytics

private extension MultiWalletMainContentViewModel {
    func logMainButtonUpgradeAnalytics() {
        Analytics.log(
            .mainButtonUpgrade,
            contextParams: .userWallet(userWalletModel.userWalletId)
        )
    }
}
