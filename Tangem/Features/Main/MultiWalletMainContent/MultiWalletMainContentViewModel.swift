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
import TangemVisa
import BlockchainSdk
import struct TangemUIUtils.AlertBinder
import TangemPay

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
    @Published var tangemPaySyncInProgress: Bool = false

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    @Published var tangemPayAccountViewModel: TangemPayAccountViewModel?

    @Published var isScannerBusy = false
    @Published var error: AlertBinder? = nil
    @Published var nftEntrypointViewModel: NFTEntrypointViewModel?

    @Published var tokenItemPromoBubbleViewModel: TokenItemPromoBubbleViewModel?

    weak var delegate: MultiWalletMainContentDelegate?

    var footerViewModel: MainFooterViewModel?

    private(set) lazy var bottomSheetFooterViewModel = MainBottomSheetFooterViewModel()

    @Published private(set) var actionButtonsViewModel: ActionButtonsViewModel?
    @Published private(set) var tangemPayBannerViewModel: GetTangemPayBannerViewModel?

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

    // MARK: - Dependencies

    @Injected(\.mobileFinishActivationManager) private var mobileFinishActivationManager: MobileFinishActivationManager
    @Injected(\.tangemPayAvailabilityRepository) private var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository

    private let nftFeatureLifecycleHandler: NFTFeatureLifecycleHandling
    private let userWalletModel: UserWalletModel
    private let userWalletNotificationManager: NotificationManager
    private let sectionsProvider: any MultiWalletMainContentViewSectionsProvider
    private let tokensNotificationManager: NotificationManager
    private let bannerNotificationManager: NotificationManager?
    private let tangemPayNotificationManager: NotificationManager
    private let tokenRouter: SingleTokenRoutable
    private let rateAppController: RateAppInteractionController
    private let balanceRestrictionFeatureAvailabilityProvider: BalanceRestrictionFeatureAvailabilityProvider
    private weak var coordinator: (MultiWalletMainContentRoutable & ActionButtonsRoutable & NFTEntrypointRoutable)?
    private let tokenItemPromoProvider: TokenItemPromoProvider

    private var derivator: TokenEntriesDerivator?

    private var canManageTokens: Bool { userWalletModel.config.hasFeature(.multiCurrency) }

    private let isPageSelectedSubject = PassthroughSubject<Bool, Never>()

    @MainActor
    private var isUpdating = false

    private var bag = Set<AnyCancellable>()

    init(
        userWalletModel: UserWalletModel,
        userWalletNotificationManager: NotificationManager,
        sectionsProvider: any MultiWalletMainContentViewSectionsProvider,
        tokensNotificationManager: NotificationManager,
        bannerNotificationManager: NotificationManager?,
        tangemPayNotificationManager: NotificationManager,
        rateAppController: RateAppInteractionController,
        nftFeatureLifecycleHandler: NFTFeatureLifecycleHandling,
        tokenRouter: SingleTokenRoutable,
        coordinator: (MultiWalletMainContentRoutable & ActionButtonsRoutable & NFTEntrypointRoutable)?,
        tokenItemPromoProvider: TokenItemPromoProvider
    ) {
        self.userWalletModel = userWalletModel
        self.userWalletNotificationManager = userWalletNotificationManager
        self.sectionsProvider = sectionsProvider
        self.tokensNotificationManager = tokensNotificationManager
        self.bannerNotificationManager = bannerNotificationManager
        self.tangemPayNotificationManager = tangemPayNotificationManager
        self.rateAppController = rateAppController
        self.tokenRouter = tokenRouter
        self.coordinator = coordinator
        self.nftFeatureLifecycleHandler = nftFeatureLifecycleHandler
        self.tokenItemPromoProvider = tokenItemPromoProvider

        balanceRestrictionFeatureAvailabilityProvider = BalanceRestrictionFeatureAvailabilityProvider(
            userWalletConfig: userWalletModel.config,
            walletModelsPublisher: AccountsFeatureAwareWalletModelsResolver.walletModelsPublisher(for: userWalletModel),
            updatePublisher: userWalletModel.updatePublisher
        )

        sectionsProvider.configure(with: self)
        tangemPayNotificationManager.setupManager(with: self)

        bind()
        setupActionButtons()
        setupTangemPayIfNeeded()
    }

    deinit {
        AppLogger.debug("\(userWalletModel.name) deinit")
    }

    func onDidAppear() {
        mobileFinishActivationManager.onMain(
            userWalletModel: userWalletModel,
            isAppeared: true
        )
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
        await refreshActionButtonsData()
        await MultiWalletMainContentUpdater.scheduleUpdate(with: userWalletModel)
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

    func startBackupProcess() {
        if let input = userWalletModel.backupInput {
            Analytics.log(.mainNoticeBackupWalletTapped)
            coordinator?.openOnboardingModal(with: .input(input))
        }
    }

    func onOpenOrganizeTokensButtonTap() {
        openOrganizeTokens()
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

        let nftEntrypointViewModelPublisher = if FeatureProvider.isAvailable(.accounts) {
            AccountWalletModelsAggregator
                .walletModelsPublisher(from: userWalletModel.accountModelsManager)
                .withLatestFrom(walletsWithNFTEnabledPublisher)
                .merge(with: walletsWithNFTEnabledPublisher)
        } else {
            // accounts_fixes_needed_none
            userWalletModel
                .walletModelsManager
                .walletModelsPublisher
                .withLatestFrom(walletsWithNFTEnabledPublisher)
                .merge(with: walletsWithNFTEnabledPublisher)
        }

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
            .handleEvents(receiveOutput: { [weak self] output in
                guard let output, let walletModel = self?.findWalletModel(with: output.walletModelId) else {
                    return
                }

                let logger = CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)
                logger.logYieldNoticeShown()
            })
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, output in
                output.flatMap(viewModel.makeTokenItemPromoViewModel(from:))
            }
            .assign(to: \.tokenItemPromoBubbleViewModel, on: self, ownership: .weak)
            .store(in: &bag)

        subscribeToTokenListSync(
            plainSectionsPublisher: plainSectionsPublisher,
            accountSectionsPublisher: accountSectionsPublisher
        )

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

        nftFeatureLifecycleHandler.startObserving()
    }

    private func setupTangemPayIfNeeded() {
        tangemPayNotificationManager
            .notificationPublisher
            .receiveOnMain()
            .assign(to: &$tangemPayNotificationInputs)

        let tangemPayManager = userWalletModel.tangemPayManager

        tangemPayManager
            .statePublisher
            .map(\.isSyncInProgress)
            .receiveOnMain()
            .assign(to: &$tangemPaySyncInProgress)

        tangemPayManager
            .statePublisher
            .map(\.isInitial)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .map { viewModel, isInitial in
                if isInitial {
                    nil
                } else {
                    TangemPayAccountViewModel(
                        tangemPayManager: tangemPayManager,
                        router: viewModel
                    )
                }
            }
            .receiveOnMain()
            .assign(to: &$tangemPayAccountViewModel)

        tangemPayAvailabilityRepository
            .shouldShowGetTangemPayBanner(
                for: userWalletModel.userWalletId.stringValue
            )
            .withWeakCaptureOf(self)
            .map { viewModel, shouldShow in
                shouldShow
                    ? GetTangemPayBannerViewModel(
                        onBannerTap: { [weak viewModel] in
                            viewModel?.coordinator?.openGetTangemPay()
                        }
                    )
                    : nil
            }
            .receiveOnMain()
            .assign(to: &$tangemPayBannerViewModel)
    }

    private func setupActionButtons() {
        actionButtonsViewModel = makeActionButtonsViewModel()
    }

    /// - Note: This method throws an opaque error if the NFT Entrypoint view model is already created and there is no need to update it.
    private func makeNFTEntrypointViewModelIfNeeded(isNFTEnabledForWallet: Bool) throws -> NFTEntrypointViewModel? {
        let hasWallets = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel).isNotEmpty

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
            // accounts_fixes_needed_none
            walletModelsManager: userWalletModel.walletModelsManager
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
        let didSyncTokenListPublisher = if FeatureProvider.isAvailable(.accounts) {
            userWalletModel
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
        } else {
            // [REDACTED_TODO_COMMENT]
            userWalletModel
                .userTokensManager // accounts_fixes_needed_none
                .initializedPublisher
                .filter { $0 }
                .zip(plainSectionsPublisher) // When accounts aren't enabled, we rely only on plain sections
                .mapToVoid()
                .eraseToAnyPublisher()
        }

        didSyncTokenListPublisher
            .prefix(1)
            .mapToValue(false)
            .receiveOnMain()
            .assign(to: &$isLoadingTokenList)
    }

    private func makeApyBadgeTapAction(tokenItem: TokenItem) -> ((TokenItem) -> Void)? {
        guard let walletModel = findAvailableWalletModel(for: tokenItem) else {
            return nil
        }

        if let stakingManager = walletModel.stakingManager {
            return { [weak self] _ in
                self?.handleStakingApyBadgeTapped(walletModel: walletModel, stakingManager: stakingManager)
            }
        }

        if let yieldAction = makeYieldApyBadgeTapAction(walletModel: walletModel) {
            return yieldAction
        }

        return nil
    }

    private func findAvailableWalletModel(for tokenItem: TokenItem) -> (any WalletModel)? {
        guard let result = try? WalletModelFinder.findWalletModel(userWalletId: userWalletModel.userWalletId, tokenItem: tokenItem),
              TokenActionAvailabilityProvider(
                  userWalletConfig: result.userWalletModel.config,
                  walletModel: result.walletModel
              ).isTokenInteractionAvailable()
        else {
            return nil
        }

        return result.walletModel
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
            if let apy = yieldManager.state?.marketInfo?.apy {
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

    private func makeTokenItemPromoViewModel(from output: TokenItemPromoProviderOutput) -> TokenItemPromoBubbleViewModel? {
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
                      let walletModel = AccountsFeatureAwareWalletModelsResolver
                      .walletModels(for: userWalletModel)
                      .first(where: { model in model.id == output.walletModelId })
                else {
                    return
                }

                let logger = CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: userWalletModel.userWalletId)
                logger.logYieldNoticeClicked()
                let navAction = self?.makeYieldApyBadgeTapAction(walletModel: walletModel)
                navAction?(walletModel.tokenItem)
            }
        )
    }

    private func findWalletModel(with id: WalletModelId) -> (any WalletModel)? {
        // accounts_fixes_needed_none
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

    private func openOrganizeTokens() {
        coordinator?.openOrganizeTokens(for: userWalletModel)
    }

    private func openCloreMigration() {
        guard let walletModel = findCloreWalletModelForMigration() else {
            return
        }

        coordinator?.openCloreMigration(walletModel: walletModel)
    }

    private func openSupport() {
        Analytics.log(.requestSupport, params: [.source: .main])

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
        Analytics.log(.mainButtonFinalizeActivation)

        let isBackupNeeded = userWalletModel.config.hasFeature(.mnemonicBackup) && userWalletModel.config.hasFeature(.iCloudBackup)
        if isBackupNeeded {
            coordinator?.openMobileBackup(userWalletModel: userWalletModel)
        } else {
            coordinator?.openMobileBackupOnboarding(userWalletModel: userWalletModel)
        }
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

    private func findCloreWalletModelForMigration() -> (any WalletModel)? {
        let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)

        let walletModelWithBalance = walletModels.first {
            $0.tokenItem.blockchain == .clore && ($0.totalTokenBalanceProvider.balanceType.value ?? 0) > 0
        }

        return walletModelWithBalance ?? walletModels.first { $0.tokenItem.blockchain == .clore }
    }
}

// MARK: - TangemPayAccountRoutable

extension MultiWalletMainContentViewModel: TangemPayAccountRoutable {
    func openTangemPayKYCInProgressPopup(tangemPayManager: TangemPayManager) {
        coordinator?.openTangemPayKYCInProgressPopup(tangemPayManager: tangemPayManager)
    }

    func openTangemPayKYCDeclinedPopup(tangemPayManager: TangemPayManager) {
        coordinator?.openTangemPayKYCDeclinedPopup(tangemPayManager: tangemPayManager)
    }

    func openTangemPayIssuingYourCardPopup() {
        coordinator?.openTangemPayIssuingYourCardPopup()
    }

    func openTangemPayFailedToIssueCardPopup() {
        coordinator?.openTangemPayFailedToIssueCardPopup(userWalletModel: userWalletModel)
    }

    func openTangemPayMainView(tangemPayAccount: TangemPayAccount) {
        coordinator?.openTangemPayMainView(
            userWalletInfo: userWalletModel.userWalletInfo,
            tangemPayAccount: tangemPayAccount,
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
            yieldApyTapAction: { [weak self] token in
                let action = self?.makeApyBadgeTapAction(tokenItem: token)
                action?(token)
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
        case .allowPushPermissionRequest, .postponePushPermissionRequest:
            userWalletNotificationManager.dismissNotification(with: id)
        case .tangemPaySync:
            userWalletModel.tangemPayManager.syncTokens(authorizingInteractor: userWalletModel.tangemPayAuthorizingInteractor)
        case .openCloreMigration:
            openCloreMigration()
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
        case .yield:
            tokenRouter.openYieldModule(walletModel: walletModel)
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
