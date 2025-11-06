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

final class MultiWalletMainContentViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isLoadingTokenList: Bool = true
    @Published var sections: [Section] = []
    @Published var notificationInputs: [NotificationViewInput] = []
    @Published var tokensNotificationInputs: [NotificationViewInput] = []
    @Published var bannerNotificationInputs: [NotificationViewInput] = []
    @Published var yieldModuleNotificationInputs: [NotificationViewInput] = []

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

    var isOrganizeTokensVisible: Bool {
        guard canManageTokens else { return false }

        if sections.isEmpty {
            return false
        }

        let numberOfTokens = sections.reduce(0) { $0 + $1.items.count }
        let requiredNumberOfTokens = 2

        return numberOfTokens >= requiredNumberOfTokens
    }

    // MARK: - Dependencies

    private let nftFeatureLifecycleHandler: NFTFeatureLifecycleHandling
    private let userWalletModel: UserWalletModel
    private let userWalletNotificationManager: NotificationManager
    private let tokensNotificationManager: NotificationManager
    private let bannerNotificationManager: NotificationManager?
    private let tokenSectionsAdapter: TokenSectionsAdapter
    private let tokenRouter: SingleTokenRoutable
    private let optionsEditing: OrganizeTokensOptionsEditing
    private let rateAppController: RateAppInteractionController
    private let balanceRestrictionFeatureAvailabilityProvider: BalanceRestrictionFeatureAvailabilityProvider
    private weak var coordinator: (MultiWalletMainContentRoutable & ActionButtonsRoutable & NFTEntrypointRoutable)?

    private var canManageTokens: Bool { userWalletModel.config.hasFeature(.multiCurrency) }

    private var cachedTokenItemViewModels: [ObjectIdentifier: TokenItemViewModel] = [:]

    private let mappingQueue = DispatchQueue(
        label: "com.tangem.MultiWalletMainContentViewModel.mappingQueue",
        qos: .userInitiated
    )

    private let isPageSelectedSubject = PassthroughSubject<Bool, Never>()
    private var isUpdating = false

    private var bag = Set<AnyCancellable>()

    init(
        userWalletModel: UserWalletModel,
        userWalletNotificationManager: NotificationManager,
        tokensNotificationManager: NotificationManager,
        bannerNotificationManager: NotificationManager?,
        rateAppController: RateAppInteractionController,
        tokenSectionsAdapter: TokenSectionsAdapter,
        tokenRouter: SingleTokenRoutable,
        optionsEditing: OrganizeTokensOptionsEditing,
        nftFeatureLifecycleHandler: NFTFeatureLifecycleHandling,
        coordinator: (MultiWalletMainContentRoutable & ActionButtonsRoutable & NFTEntrypointRoutable)?
    ) {
        self.userWalletModel = userWalletModel
        self.userWalletNotificationManager = userWalletNotificationManager
        self.tokensNotificationManager = tokensNotificationManager
        self.bannerNotificationManager = bannerNotificationManager
        self.rateAppController = rateAppController
        self.tokenSectionsAdapter = tokenSectionsAdapter
        self.tokenRouter = tokenRouter
        self.optionsEditing = optionsEditing
        self.coordinator = coordinator
        self.nftFeatureLifecycleHandler = nftFeatureLifecycleHandler

        balanceRestrictionFeatureAvailabilityProvider = BalanceRestrictionFeatureAvailabilityProvider(
            userWalletConfig: userWalletModel.config,
            totalBalanceProvider: userWalletModel
        )
        bind()

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
        if FeatureProvider.isAvailable(.visa) {
            let tangemPayAccountPublisher = userWalletModel.walletModelsManager.walletModelsPublisher
                .compactMap(\.visaWalletModel)
                .compactMap(TangemPayAccount.init)
                .merge(with: userWalletModel.updatePublisher.compactMap(\.tangemPayAccount))
                .share(replay: 1)

            tangemPayAccountPublisher
                .flatMapLatest(\.tangemPayNotificationManager.notificationPublisher)
                .receiveOnMain()
                .assign(to: \.tangemPayNotificationInputs, on: self, ownership: .weak)
                .store(in: &bag)

            tangemPayAccountPublisher
                .flatMapLatest(\.tangemPayCardIssuingInProgressPublisher)
                .receiveOnMain()
                .assign(to: \.tangemPayCardIssuingInProgress, on: self, ownership: .weak)
                .store(in: &bag)

            tangemPayAccountPublisher
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
                                    viewModel.openTangemPayMainView(tangemPayAccount: tangemPayAccount)
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

        await withCheckedContinuation { [weak self] checkedContinuation in
            self?.userWalletModel.userTokensManager.sync { [weak self] in
                self?.isUpdating = false
                checkedContinuation.resume()
            }
        }
    }

    func deriveEntriesWithoutDerivation() {
        Analytics.log(.mainNoticeScanYourCardTapped)
        isScannerBusy = true
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
        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()

        let tokenSectionsSourcePublisher = sourcePublisherFactory
            .makeSourcePublisherForMainScreen(for: userWalletModel)

        let organizedTokensSectionsPublisher = tokenSectionsAdapter
            .organizedSections(from: tokenSectionsSourcePublisher, on: mappingQueue)
            .share(replay: 1)

        let walletsWithNFTEnabledPublisher = nftFeatureLifecycleHandler
            .walletsWithNFTEnabledPublisher
            .share(replay: 1)

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

        let sectionsPublisher = organizedTokensSectionsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, sections in
                return viewModel.convertToSections(sections)
            }
            .receiveOnMain()
            .share(replay: 1)

        sectionsPublisher
            .assign(to: \.sections, on: self, ownership: .weak)
            .store(in: &bag)

        organizedTokensSectionsPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, sections in
                viewModel.removeOldCachedTokenViewModels(sections)
            }
            .store(in: &bag)

        organizedTokensSectionsPublisher
            .map { $0.flatMap(\.items) }
            .removeDuplicates()
            .map { $0.map(\.walletModelId) }
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, walletModelIds in
                return viewModel.optionsEditing.save(reorderedWalletModelIds: walletModelIds, source: .mainScreen)
            }
            .sink()
            .store(in: &bag)

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

        subscribeToTokenListSync(with: sectionsPublisher)
        nftFeatureLifecycleHandler.startObserving()
    }

    private func convertToSections(
        _ sections: [TokenSectionsAdapter.Section]
    ) -> [Section] {
        let factory = MultiWalletTokenItemsSectionFactory()

        if sections.count == 1, sections[0].items.isEmpty {
            return []
        }

        return sections.enumerated().map { index, section in
            let sectionViewModel = factory.makeSectionViewModel(from: section.model, atIndex: index)
            let itemViewModels = section.items.map { item in
                switch item {
                case .default(let walletModel):
                    // Fetching existing cached View Model for this Wallet Model, if available
                    let cacheKey = ObjectIdentifier(walletModel)
                    if let cachedViewModel = cachedTokenItemViewModels[cacheKey] {
                        return cachedViewModel
                    }
                    let viewModel = makeTokenItemViewModel(from: item, using: factory)
                    cachedTokenItemViewModels[cacheKey] = viewModel
                    return viewModel
                case .withoutDerivation:
                    return makeTokenItemViewModel(from: item, using: factory)
                }
            }

            return Section(model: sectionViewModel, items: itemViewModels)
        }
    }

    /// - Note: This method throws an opaque error if the NFT Entrypoint view model is already created and there is no need to update it.
    private func makeNFTEntrypointViewModelIfNeeded(isNFTEnabledForWallet: Bool) throws -> NFTEntrypointViewModel? {
        // NFT Entrypoint is shown only if the feature is enabled for the wallet and there is at least one token in the token list
        guard isNFTEnabledForWallet, userWalletModel.walletModelsManager.walletModels.isNotEmpty else {
            return nil
        }

        // Early exit when the NFT Entrypoint view model has already been created, since there is no point in creating it again
        if nftEntrypointViewModel != nil {
            throw "NFTEntrypointViewModel already created"
        }

        let navigationContext = NFTNavigationInput(
            userWalletModel: userWalletModel,
            walletModelsManager: userWalletModel.walletModelsManager
        )
        let accountForNFTCollectionsProvider = AccountForNFTCollectionProvider(
            accountModelsManager: userWalletModel.accountModelsManager
        )

        return NFTEntrypointViewModel(
            nftManager: userWalletModel.nftManager,
            accountForCollectionsProvider: accountForNFTCollectionsProvider,
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

    private func makeTokenItemViewModel(
        from sectionItem: TokenSectionsAdapter.SectionItem,
        using factory: MultiWalletTokenItemsSectionFactory
    ) -> TokenItemViewModel {
        return factory.makeSectionItemViewModel(
            from: sectionItem,
            contextActionsProvider: self,
            contextActionsDelegate: self,
            tapAction: weakify(self, forFunction: MultiWalletMainContentViewModel.tokenItemTapped(_:)),
            yieldApyTapAction: weakify(self, forFunction: MultiWalletMainContentViewModel.apyBadgeTapped(_:))
        )
    }

    private func removeOldCachedTokenViewModels(_ sections: [TokenSectionsAdapter.Section]) {
        let cacheKeys = sections
            .flatMap(\.walletModels)
            .map(ObjectIdentifier.init)
            .toSet()

        cachedTokenItemViewModels = cachedTokenItemViewModels.filter { cacheKeys.contains($0.key) }
    }

    private func subscribeToTokenListSync(with sectionsPublisher: some Publisher<[Section], Never>) {
        let tokenListSyncPublisher = userWalletModel
            .userTokenListManager
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

    private func apyBadgeTapped(_ walletModelId: WalletModelId.ID) {
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id.id == walletModelId }),
              TokenActionAvailabilityProvider(userWalletConfig: userWalletModel.config, walletModel: walletModel).isTokenInteractionAvailable()
        else {
            return
        }

        if let stakingManager = walletModel.stakingManager {
            handleStakingApyBadgeTapped(walletModel: walletModel, stakingManager: stakingManager)
        } else if let yieldModuleManager = walletModel.yieldModuleManager {
            handleYieldApyBadgeTapped(walletModel: walletModel, yieldManager: yieldModuleManager)
        } else {
            return
        }
    }

    private func handleYieldApyBadgeTapped(walletModel: any WalletModel, yieldManager: YieldModuleManager) {
        let logger = CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem)

        switch yieldManager.state?.state {
        case .active:
            logger.logEarningApyClicked(state: .enabled)
            coordinator?.openYieldModuleActiveInfo(walletModel: walletModel, signer: userWalletModel.signer)
        case .notActive:
            if let apy = yieldManager.state?.marketInfo?.apy {
                coordinator?.openYieldModulePromoView(walletModel: walletModel, apy: apy, signer: userWalletModel.signer)
                logger.logEarningApyClicked(state: .disabled)
            }
        case .disabled, .failedToLoad, .loading, .processing, .none:
            break
        }
    }

    private func handleStakingApyBadgeTapped(walletModel: any WalletModel, stakingManager: StakingManager) {
        let logger = CommonStakingAnalyticsLogger()
        let analyticsState: StakingAnalyticsState

        switch stakingManager.state {
        case .availableToStake:
            analyticsState = .disabled
        case .staked:
            analyticsState = .enabled
        case .loading, .loadingError, .temporaryUnavailable, .notEnabled:
            return
        }

        logger.logStakingApyClicked(
            state: analyticsState,
            tokenName: SendAnalyticsHelper.makeAnalyticsTokenName(from: walletModel.tokenItem),
            blockchainName: walletModel.tokenItem.blockchain.displayName
        )

        coordinator?.openStaking(
            options: .init(
                userWalletModel: userWalletModel,
                walletModel: walletModel,
                manager: stakingManager
            )
        )
    }

    private func tokenItemTapped(_ walletModelId: WalletModelId.ID) {
        guard
            let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id.id == walletModelId }),
            TokenActionAvailabilityProvider(userWalletConfig: userWalletModel.config, walletModel: walletModel).isTokenInteractionAvailable()
        else {
            return
        }

        coordinator?.openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
    }

    private func openTangemPayMainView(tangemPayAccount: TangemPayAccount) {
        coordinator?.openTangemPayMainView(tangemPayAccount: tangemPayAccount)
    }
}

// MARK: Hide token

private extension MultiWalletMainContentViewModel {
    func hideTokenAction(for tokenItemViewModel: TokenItemViewModel) {
        let tokenItem = tokenItemViewModel.tokenItem

        let alertBuilder = HideTokenAlertBuilder()
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

        let dataCollector = DetailsFeedbackDataCollector(
            data: [
                .init(
                    userWalletEmailData: userWalletModel.emailData,
                    walletModels: userWalletModel.walletModelsManager.walletModels
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

    private func openReferralProgram() {
        Analytics.log(.mainReferralProgramButtonParticipate)

        let input = ReferralInputModel(
            userWalletId: userWalletModel.userWalletId.value,
            supportedBlockchains: userWalletModel.config.supportedBlockchains,
            userTokensManager: userWalletModel.userTokensManager
        )

        coordinator?.openReferral(input: input)
    }

    private func openMobileFinishActivation(needsAttention: Bool) {
        Analytics.log(.mainButtonFinishNow)
        if needsAttention {
            coordinator?.openMobileFinishActivation(userWalletModel: userWalletModel)
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
}

// MARK: - Notification tap delegate

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
        case .openReferralProgram:
            openReferralProgram()
        case .openMobileFinishActivation(let needsAttention):
            openMobileFinishActivation(needsAttention: needsAttention)
        case .openMobileUpgrade:
            openMobileUpgrade()
        case .openBuyCrypto(let walletModel, let parameters):
            coordinator?.openOnramp(userWalletModel: userWalletModel, walletModel: walletModel, parameters: parameters)
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

// MARK: Context actions

extension MultiWalletMainContentViewModel: TokenItemContextActionsProvider {
    func buildContextActions(for tokenItemViewModel: TokenItemViewModel) -> [TokenContextActionsSection] {
        let actionBuilder = TokenContextActionsSectionBuilder()
        return actionBuilder.buildContextActionsSections(
            tokenItem: tokenItemViewModel.tokenItem,
            walletModelId: tokenItemViewModel.id,
            userWalletModel: userWalletModel,
            canNavigateToMarketsDetails: true,
            canHideToken: canManageTokens
        )
    }
}

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
            let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == tokenItemViewModel.id })
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

// MARK: - Auxiliary types

extension MultiWalletMainContentViewModel {
    typealias Section = SectionModel<SectionViewModel, TokenItemViewModel>

    struct SectionViewModel: Identifiable {
        let id: AnyHashable
        let title: String?
    }
}

// MARK: - Convenience extensions

private extension TokenSectionsAdapter.Section {
    var walletModels: [any WalletModel] {
        return items.compactMap(\.walletModel)
    }
}

// MARK: - Action buttons

private extension MultiWalletMainContentViewModel {
    func makeActionButtonsViewModel() -> ActionButtonsViewModel? {
        guard let coordinator, canManageTokens else { return nil }

        return .init(
            coordinator: coordinator,
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletModel: userWalletModel),
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
