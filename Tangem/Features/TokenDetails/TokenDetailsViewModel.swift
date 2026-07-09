//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk
import TangemExpress
import TangemStaking
import TangemFoundation
import TangemLocalization
import TangemUI
import struct TangemUIUtils.ConfirmationDialogViewModel
import TangemAccessibilityIdentifiers

final class TokenDetailsViewModel: SingleTokenBaseViewModel, ObservableObject {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    @Published var exploreConfirmationDialog: ConfirmationDialogViewModel?
    @Published var yieldModuleAvailability: YieldModuleAvailability = .checking
    @Published private(set) var quickTopUpBannerViewModel: QuickTopUpBannerViewModel?
    @Published var dotsMenuItems: [DotsMenuItem] = []

    @Published private(set) var isZeroBalance = true
    @Published private(set) var marketPriceViewModel: TokenDetailsMarketPriceViewModel?

    private(set) lazy var navigationBarViewModel = makeNavigationBarViewModel()

    // [REDACTED_INFO]: Remove when the redesign feature toggle is removed

    private(set) lazy var balanceWithButtonsModel = BalanceWithButtonsViewModel(
        tokenItem: walletModel.tokenItem,
        buttonsPublisher: $actionButtons.eraseToAnyPublisher(),
        balanceProvider: self,
        balanceTypeSelectorProvider: self,
        yieldModuleStatusProvider: self,
        refreshStatusProvider: self,
        showYieldBalanceInfoAction: { [weak self] in
            self?.openYieldBalanceInfo()
        },
        reloadBalance: { @MainActor [weak self] in
            await self?.onPullToRefresh()
        }
    )

    private(set) lazy var balanceViewModel = TokenDetailsBalanceViewModel(
        tokenItem: walletModel.tokenItem,
        dataProvider: self,
        reloadBalance: {
            Task { @MainActor [weak self] in
                await self?.onPullToRefresh()
            }
        }
    )

    let actionsViewModel: TokenDetailsActionsViewModel?

    private(set) lazy var tokenDetailsHeaderModel: TokenDetailsHeaderViewModel = .init(tokenItem: walletModel.tokenItem)

    @Published private(set) var activeStakingViewData: ActiveStakingViewData?
    @Published private(set) var stakingState: TokenDetailsStakingState?
    @Published private(set) var yieldState: TokenDetailsYieldState?

    var iconUrl: URL? {
        guard let id = walletModel.tokenItem.id else {
            return nil
        }

        return IconURLBuilder().tokenIconURL(id: id)
    }

    var customTokenColor: Color? {
        walletModel.tokenItem.token?.customTokenColor
    }

    let presentSource: TokenDetailsPresentSource

    private weak var coordinator: (any TokenDetailsRoutable)?
    private let xpubGenerator: XPUBGenerator?
    private let pendingTransactionDetails: PendingTransactionDetails?
    private let userTokensManager: any UserTokensManager

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()
    private var bag = Set<AnyCancellable>()

    private lazy var yieldStateFactory = TokenDetailsYieldStateFactory(
        walletModel: walletModel,
        coordinator: coordinator,
        factoryBuilder: { [weak self] manager in
            self?.makeYieldModuleFlowFactory(manager: manager)
        }
    )

    private lazy var yieldAvailabilityBuilder = TokenDetailsYieldAvailabilityFactory(
        walletModel: walletModel,
        coordinator: coordinator,
        factoryBuilder: { [weak self] manager in
            self?.makeYieldModuleFlowFactory(manager: manager)
        }
    )

    init(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel,
        notificationManager: NotificationManager,
        userTokensManager: any UserTokensManager,
        pendingExpressTransactionsManager: PendingExpressTransactionsManager,
        xpubGenerator: XPUBGenerator?,
        coordinator: any TokenDetailsRoutable,
        tokenRouter: SingleTokenRoutable,
        pendingTransactionDetails: PendingTransactionDetails?,
        presentSource: TokenDetailsPresentSource
    ) {
        self.coordinator = coordinator
        self.xpubGenerator = xpubGenerator
        self.pendingTransactionDetails = pendingTransactionDetails
        self.userTokensManager = userTokensManager
        self.presentSource = presentSource

        actionsViewModel = FeatureProvider.isAvailable(.redesign)
            ? TokenDetailsActionsViewModel(walletModel: walletModel, userWalletInfo: userWalletInfo)
            : nil

        super.init(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            notificationManager: notificationManager,
            pendingExpressTransactionsManager: pendingExpressTransactionsManager,
            tokenRouter: tokenRouter
        )

        actionsViewModel?.setRoutable(self)

        notificationManager.setupManager(with: self)

        prepareSelf()
    }

    deinit {
        AppLogger.debug("TokenDetailsViewModel deinit")
    }

    func onBack() {
        coordinator?.dismiss()
    }

    func onAppear() {
        logScreenOpenedAnalytics()
    }

    func onFirstAppear() {
        walletModel.yieldModuleManager?.sendActivationState()
    }

    override func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .empty,
             .unlock,
             .yieldBoostPromoLater,
             .openGetTangemPay,
             .closeGetTangemPay:
            break
        case .openFeeCurrency:
            coordinator?.proceedFeeCurrencyNavigatingDismissOption(
                option: .init(walletModel: walletModel)
            )
        case .swap:
            openExchange()
        case .openCloreMigration:
            openCloreMigration()
        case .openDynamicAddressesEnter:
            if let walletModelDynamicAddressesProvider = walletModel as? WalletModelDynamicAddressesProvider {
                openDynamicAddressesManagementView(
                    walletModelDynamicAddressesProvider: walletModelDynamicAddressesProvider
                )
            }
        case .generateAddresses,
             .backupCard,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .addHederaTokenAssociation,
             .retryKaspaTokenTransaction,
             .leaveAmount,
             .openLink,
             .openDeeplink,
             .stake,
             .openFeedbackMail,
             .openAppStoreReview,
             .backupErrorSupport,
             .openCurrency,
             .addTokenTrustline,
             .openMobileFinishActivation,
             .openMobileUpgrade,
             .closeMobileUpgrade,
             .activate,
             .allowPushPermissionRequest,
             .postponePushPermissionRequest,
             .givePermission,
             .openManageTokensAfterWalletSuccessImport,
             .renewTangemPaySession,
             .openPushNotificationsSystemSettings,
             .openYieldBoostPromo,
             .addFunds:
            super.didTapNotification(with: id, action: action)
        }
    }

    override func present(exploreConfirmationDialog: ConfirmationDialogViewModel) {
        self.exploreConfirmationDialog = exploreConfirmationDialog
    }

    override func copyDefaultAddress() {
        if let unavailableAlert = tokenActionAvailabilityAlertBuilder.alert(
            for: tokenActionAvailabilityProvider.receiveAvailability, blockchain: blockchain
        ) {
            alert = unavailableAlert
            return
        }

        super.copyDefaultAddress()
        Analytics.log(
            event: .buttonCopyAddress,
            params: [
                .token: walletModel.tokenItem.currencySymbol,
                .source: Analytics.ParameterValue.token.rawValue,
            ],
            analyticsSystems: .all
        )
        Toast(
            view: SuccessToast(text: Localization.walletNotificationAddressCopied)
                .accessibilityIdentifier(ActionButtonsAccessibilityIdentifiers.addressCopiedToast)
        )
        .present(
            layout: .bottom(padding: 80),
            type: .temporary()
        )
    }

    override func openMarketsTokenDetails() {
        guard isMarketsDetailsAvailable else {
            return
        }

        let analyticsParams: [Analytics.ParameterKey: String] = [
            .source: Analytics.ParameterValue.token.rawValue,
            .token: walletModel.tokenItem.currencySymbol.uppercased(),
            .blockchain: walletModel.tokenItem.blockchain.displayName,
        ]
        Analytics.log(event: .marketsChartScreenOpened, params: analyticsParams)
        super.openMarketsTokenDetails()
    }
}

// MARK: - Hide token

extension TokenDetailsViewModel {
    func hideTokenButtonAction() {
        if userTokensManager.canRemove(walletModel.tokenItem) {
            showHideWarningAlert()
        } else {
            showUnableToHideAlert()
        }
    }

    func generateXPUBButtonAction(xpubGenerator: XPUBGenerator) {
        runTask { [weak self] in
            do {
                let xpub = try await xpubGenerator.generateXPUB()
                await runOnMain {
                    MainActor.assumeIsolated {
                        let viewController = UIActivityViewController(activityItems: [xpub], applicationActivities: nil)
                        AppPresenter.shared.show(viewController)
                    }
                }
            } catch {
                let sdkError = error.toTangemSdkError()
                if !sdkError.isUserCancelled {
                    await runOnMain {
                        self?.alert = error.alertBinder
                    }
                }
            }
        }
    }

    func openDynamicAddressesDisableView(walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider) {
        let analyticsLogger = CommonDynamicAddressesAnalyticsLogger(tokenItem: walletModel.tokenItem)

        let transferableToken = CommonSendTransferableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        )
        .makeTransferableToken(supportingFeeOptions: .compound)

        let compoundFlowBaseDependenciesFactory = CommonDynamicAddressesCompoundFlowBaseDependenciesFactory(
            transferableToken: transferableToken
        )

        coordinator?.openDynamicAddressesDisableSheet(
            walletModelDynamicAddressesProvider: walletModelDynamicAddressesProvider,
            compoundFlowBaseDependenciesFactory: compoundFlowBaseDependenciesFactory,
            analyticsLogger: analyticsLogger
        )
    }

    func openDynamicAddressesEnableView(walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider) {
        switch walletModelDynamicAddressesProvider.dynamicAddressesEnablingRequirements {
        case .customTokensRemoveIsNeeded:
            coordinator?.openDynamicAddressesUnavailableSheet(messageType: .hasCustomToken)
        default:
            // Other enabling requirements will handle in `DynamicAddressesEnterView`
            let analyticsLogger = CommonDynamicAddressesAnalyticsLogger(tokenItem: walletModel.tokenItem)
            coordinator?.openDynamicAddressesEnterView(
                walletModelDynamicAddressesProvider: walletModelDynamicAddressesProvider,
                analyticsLogger: analyticsLogger
            )
        }
    }

    func openDynamicAddressesManagementView(walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider) {
        let availabilityProvider = TokenActionAvailabilityProvider(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        )

        if let unavailableAlert = TokenActionAvailabilityAlertBuilder().alert(for: availabilityProvider.dynamicAddressesAvailability) {
            alert = unavailableAlert
            return
        }

        if walletModel.tokenItem.blockchainNetwork.isDynamicAddressesEnabled() {
            openDynamicAddressesDisableView(walletModelDynamicAddressesProvider: walletModelDynamicAddressesProvider)
        } else {
            openDynamicAddressesEnableView(walletModelDynamicAddressesProvider: walletModelDynamicAddressesProvider)
        }
    }

    private func showUnableToHideAlert() {
        let tokenName = walletModel.tokenItem.name
        let message = Localization.tokenDetailsUnableHideAlertMessage(
            tokenName,
            currencySymbol,
            blockchain.displayName
        )

        alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: Localization.tokenDetailsUnableHideAlertTitle(tokenName),
            message: message,
            buttonText: Localization.commonOk
        )
    }

    private func showHideWarningAlert() {
        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsHideAlertTitle(walletModel.tokenItem.name),
            message: Localization.tokenDetailsHideAlertMessage,
            primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide)) { [weak self] in
                self?.hideToken()
            },
            secondaryButton: .cancel()
        )
    }

    private func hideToken() {
        Analytics.log(
            event: .buttonRemoveToken,
            params: [
                Analytics.ParameterKey.token: currencySymbol,
                Analytics.ParameterKey.source: Analytics.ParameterValue.token.rawValue,
            ]
        )

        userTokensManager.remove(walletModel.tokenItem)
        coordinator?.dismiss()
    }
}

// MARK: - Analytics

private extension TokenDetailsViewModel {
    func logScreenOpenedAnalytics() {
        let balanceState: Analytics.ParameterValue = switch walletModel.availableBalanceProvider.balanceType {
        case .empty:
            .empty
        case .loading:
            .loading
        case .failure:
            .error
        case .loaded(let amount) where amount == .zero:
            .empty
        case .loaded:
            .full
        }

        var params: [Analytics.ParameterKey: String] = [
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.tokenItem.blockchain.displayName,
            .balance: balanceState.rawValue,
        ]

        if walletModel.tokenItem.blockchain.isDynamicAddressesSupported {
            let isEnabled = walletModel.tokenItem.blockchainNetwork.isDynamicAddressesEnabled()
            params[.dynamicAddress] = Analytics.ParameterValue.boolState(for: isEnabled).rawValue
        }

        Analytics.log(event: .detailsScreenOpened, params: params)
    }
}

// MARK: - Setup functions

private extension TokenDetailsViewModel {
    private func prepareSelf() {
        Task { @MainActor [notificationManager, weak self] in
            let tokenNotificationInputs = await notificationManager.notificationInputs

            guard self?.isRedesign == true else {
                self?.tokenNotificationInputs = tokenNotificationInputs
                return
            }

            self?.notifications = MultiWalletNotificationBannerMapper().mapItems(tokenNotificationInputs)
        }

        setupQuickTopUpBanner()
        dotsMenuItems = makeDotsMenuItems()
        marketPriceViewModel = makeMarketPriceViewModel()

        bind()
    }

    private func setupQuickTopUpBanner() {
        expressAvailabilityProvider.availabilityDidChangePublisher
            .receiveOnMain()
            .map { [weak self] in self?.mapToQuickTopUpBannerViewModel() }
            .assign(to: &$quickTopUpBannerViewModel)
    }

    private func mapToQuickTopUpBannerViewModel() -> QuickTopUpBannerViewModel? {
        let availabilityProvider = TokenActionAvailabilityProvider(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        )
        guard availabilityProvider.isBuyAvailable else { return nil }
        if let existing = quickTopUpBannerViewModel { return existing }

        let sourceToken = CommonSendSourceTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        ).makeSourceToken()

        return QuickTopUpBannerViewModel(
            sourceToken: sourceToken,
            onOpenOnramp: { [weak self] parameters in
                self?.openOnramp(parameters: parameters)
            }
        )
    }

    private func makeDotsMenuItems() -> [DotsMenuItem] {
        var items: [DotsMenuItem] = []

        if let xpubGenerator {
            items.append(DotsMenuItem(type: .generateXPUB) { [weak self] in
                self?.generateXPUBButtonAction(xpubGenerator: xpubGenerator)
            })
        }

        let isDynamicAddressesSupported = walletModel.tokenItem.blockchain.isDynamicAddressesSupported
        // Dynamic addresses derive multiple receive addresses from an XPUB, so they require an HD wallet.
        // Single-currency cards (Note, Twin, Start2Coin, legacy) lack HD derivation and must not offer it.
        let isHDWalletsSupported = userWalletInfo.config.hasFeature(.hdWallets)
        let walletModelDynamicAddressesProvider = walletModel as? WalletModelDynamicAddressesProvider

        if let walletModelDynamicAddressesProvider, isDynamicAddressesSupported, isHDWalletsSupported {
            items.append(DotsMenuItem(type: .dynamicAddresses) { [weak self] in
                self?.openDynamicAddressesManagementView(
                    walletModelDynamicAddressesProvider: walletModelDynamicAddressesProvider
                )
            })
        }

        if userWalletInfo.config.hasFeature(.multiCurrency) {
            items.append(DotsMenuItem(type: .hideToken) { [weak self] in
                self?.hideTokenButtonAction()
            })
        }

        return items
    }

    private func bind() {
        walletModel.yieldModuleManager?.statePublisher
            .compactMap { $0 }
            .filter { !$0.state.isLoading }
            .receiveOnMain()
            .removeDuplicates()
            .sink { [weak self] info in
                self?.updateYield(info: info)
            }
            .store(in: &bag)

        // If a pending transaction was provided for deeplink-based presentation,
        // wait for the first non-empty list of pending transactions,
        // and if it contains a transaction matching the provided ID, present its status.
        if let pendingTransactionDetails {
            $pendingExpressTransactions
                .filter { !$0.isEmpty }
                .prefix(1)
                .sink { [weak self] pendingTransactions in
                    guard let self,
                          let matchingTransaction = pendingTransactions.first(where: { $0.id == pendingTransactionDetails.id })
                    else {
                        return
                    }

                    didTapPendingExpressTransaction(id: matchingTransaction.id)
                }
                .store(in: &bag)
        }

        walletModel.stakingManagerStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                AppLogger.info("Token details receive new StakingManager state: \(state)")
                self?.updateStaking(state: state)
            }
            .store(in: &bag)

        $miniChartData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chartData in
                MainActor.assumeIsolated {
                    self?.updateMarketPrice(miniChartData: chartData)
                }
            }
            .store(in: &bag)

        walletModel.availableBalanceProvider
            .balanceTypePublisher
            .removeDuplicates()
            .compactMap { balance in
                balance.value ?? .zero == .zero
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isZeroBalance in
                // [REDACTED_TODO_COMMENT]
                self?.isZeroBalance = isZeroBalance
            }
            .store(in: &bag)
    }

    private func updateYield(info: YieldModuleManagerStateInfo) {
        if isRedesign {
            updateRedesignYield(info: info)
        } else {
            updateYieldAvailability(state: info)
        }
    }

    private func updateRedesignYield(info: YieldModuleManagerStateInfo) {
        yieldState = yieldStateFactory.make(info: info)
    }

    private func updateStaking(state: StakingManagerState) {
        if isRedesign {
            updateRedesignStaking(state: state)
        } else {
            updateLegacyStaking(state: state)
        }
    }

    private func updateRedesignStaking(state: StakingManagerState) {
        switch state {
        case .loading:
            stakingState = .loading
        case .availableToStake(let info):
            stakingState = makeAvailableStakingState(info: info)
        case .staked(let staked):
            stakingState = makeEnableStakingState(staked: staked)
        case .loadingError, .temporaryUnavailable:
            stakingState = makeUnavailableStakingState()
        case .notEnabled:
            stakingState = nil
        }
    }

    private func makeAvailableStakingState(info: StakingYieldInfo) -> TokenDetailsStakingState {
        let rewardPercent = PercentFormatter().format(info.rewardRateValues.max, option: .staking)

        let description = switch info.rewardType {
        case .apr: Localization.tokenDetailsEarnStakingSubtitle(rewardPercent)
        case .apy: Localization.tokenDetailsEarnStakingSubtitleApy(rewardPercent)
        }

        let item = TokenDetailsStakingState.AvailableItem(
            title: Localization.tokenDetailsStakingBlockTitle,
            description: description,
            actionTitle: Localization.commonStake,
            action: weakify(self, forFunction: TokenDetailsViewModel.openStaking)
        )

        return .available(item: item)
    }

    private func makeEnableStakingState(staked: StakingManagerState.Staked) -> TokenDetailsStakingState {
        let rewardsState = makeStakingRewardsState(staked: staked)

        let balance = staked.balances.stakes().sum()

        let cryptoBalance = balanceFormatter.formatCryptoBalance(
            balance,
            currencyCode: walletModel.tokenItem.currencySymbol
        )

        let fiatBalance = walletModel.tokenItem.currencyId.flatMap { currencyId in
            balanceConverter.convertToFiat(balance, currencyId: currencyId)
        }
        let formattedFiatBalance = balanceFormatter.formatFiatBalance(fiatBalance)
        let attributedFiatBalance = TangemTokenRowBalanceFormatter.formatWithDecimalColoring(
            formattedFiatBalance,
            font: Font.Tangem.Body16.medium,
            integerColor: .Tangem.Text.Neutral.primary,
            decimalColor: .Tangem.Text.Neutral.secondary
        )

        let item = TokenDetailsStakingState.EnableItem(
            title: Localization.stakingEnabled,
            rewardsState: rewardsState,
            fiatBalance: attributedFiatBalance,
            cryptoBalance: cryptoBalance,
            action: weakify(self, forFunction: TokenDetailsViewModel.openStaking)
        )
        return .enable(item: item)
    }

    private func makeUnavailableStakingState() -> TokenDetailsStakingState {
        let item = TokenDetailsStakingState.UnavailableItem(
            title: Localization.commonStaking,
            description: Localization.stakingNotificationNetworkErrorText
        )
        return .unavailable(item: item)
    }

    private func makeStakingRewardsState(staked: StakingManagerState.Staked) -> TokenDetailsStakingState.RewardsState {
        switch (staked.yieldInfo.rewardClaimingType, staked.balances.rewards().sum()) {
        case (.auto, _):
            return .auto
        case (.manual, .zero):
            return .empty(Localization.stakingDetailsNoRewardsToClaim)
        case (.manual, let rewards):
            let fiat: Decimal? = walletModel.tokenItem.currencyId.flatMap { currencyId in
                balanceConverter.convertToFiat(rewards, currencyId: currencyId)
            }
            let formattedFiat = balanceFormatter.formatFiatBalance(fiat)
            return .claimed(formattedFiat)
        }
    }

    private func updateLegacyStaking(state: StakingManagerState) {
        let isBeta = state.yieldInfo?.item.network == .ethereum

        switch state {
        case .loading:
            // Do nothing
            break
        case .availableToStake, .notEnabled:
            activeStakingViewData = nil
        case .loadingError, .temporaryUnavailable:
            activeStakingViewData = .init(isBeta: isBeta, balance: .loadingError, rewards: .none)
        case .staked(let staked):
            let rewards = mapToRewardsState(staked: staked)
            let balance = mapToStakedBalance(staked: staked)

            activeStakingViewData = ActiveStakingViewData(
                isBeta: isBeta,
                balance: .balance(balance) { [weak self] in self?.openStaking() },
                rewards: rewards
            )
        }
    }

    @MainActor
    private func updateMarketPrice(miniChartData: LoadingResult<[Double], any Error>) {
        switch miniChartData {
        case .success(let chartPoints):
            marketPriceViewModel?.miniChartPoints = LoadingResult.success(chartPoints)

        case .loading, .failure:
            marketPriceViewModel?.miniChartPoints = LoadingResult.loading
        }
    }

    func mapToRewardsState(staked: StakingManagerState.Staked) -> ActiveStakingViewData.RewardsState? {
        switch (staked.yieldInfo.rewardClaimingType, staked.balances.rewards().sum()) {
        case (.auto, let rewards) where staked.yieldInfo.item.network == .ethereum && rewards > 0:
            let formatted = balanceFormatter.formatCryptoBalance(
                rewards,
                currencyCode: walletModel.tokenItem.currencySymbol
            )
            return .compoundedRewardsEarned(formatted)
        case (.auto, _):
            return nil
        case (.manual, .zero):
            return .noRewards
        case (.manual, let rewards):
            let stakedRewardsFiat: Decimal? = walletModel.tokenItem.currencyId.flatMap { currencyId in
                balanceConverter.convertToFiat(rewards, currencyId: currencyId)
            }
            let formatted = balanceFormatter.formatFiatBalance(stakedRewardsFiat)
            return .rewardsToClaim(formatted)
        }
    }

    func mapToStakedBalance(staked: StakingManagerState.Staked) -> BalanceFormatted {
        let stakedWithPendingBalance = staked.balances.stakes().sum()
        let stakedWithPendingBalanceFormatted = balanceFormatter.formatCryptoBalance(stakedWithPendingBalance, currencyCode: walletModel.tokenItem.currencySymbol)

        let stakedWithPendingFiatBalance = walletModel.tokenItem.currencyId.flatMap { currencyId in
            balanceConverter.convertToFiat(stakedWithPendingBalance, currencyId: currencyId)
        }
        let stakedWithPendingFiatBalanceFormatted = balanceFormatter.formatFiatBalance(stakedWithPendingFiatBalance)

        return .init(
            crypto: stakedWithPendingBalanceFormatted,
            fiat: stakedWithPendingFiatBalanceFormatted
        )
    }

    private func updateYieldAvailability(state: YieldModuleManagerStateInfo) {
        yieldModuleAvailability = yieldAvailabilityBuilder.make(state: state.state, marketInfo: state.marketInfo)
    }

    private func makeNavigationBarViewModel() -> TokenDetailsNavigationBarViewModel {
        let tokenStorage: TokenDetailsNavigationBarViewModel.TokenStorage
        let headerProvider = TokenHeaderProvider(userWalletName: userWalletInfo.name, account: walletModel.account)

        switch headerProvider.makeHeader() {
        case .account(let accountName, let accountIcon):
            tokenStorage = .account(icon: accountIcon, name: accountName)

        case .wallet(name: let walletName, hasOnlyOneWallet: false):
            tokenStorage = .wallet(name: walletName, icon: userWalletInfo.config.walletThumbnailType)

        case .wallet(_, hasOnlyOneWallet: true):
            tokenStorage = .singleWallet
        }

        let title = TokenDetailsNavigationBarViewModel.Title(
            tokenName: walletModel.tokenItem.name,
            storedIn: tokenStorage
        )

        let subtitle: String

        if walletModel.tokenItem.isToken {
            let tokenName = walletModel.tokenItem.blockchain.tokenTypeName ?? Localization.commonToken
            let networkName = walletModel.tokenItem.blockchain.displayName
            let preposition = Localization.commonIn
            let network = Localization.wcCommonNetwork.lowercased()
            subtitle = "\(tokenName) \(preposition) \(networkName) \(network)"
        } else {
            subtitle = Localization.commonMainNetwork
        }

        return TokenDetailsNavigationBarViewModel(title: title, subtitle: subtitle)
    }

    private func makeMarketPriceViewModel() -> TokenDetailsMarketPriceViewModel? {
        guard isRedesign, walletModel.tokenItem.id != nil else {
            return nil
        }

        return TokenDetailsMarketPriceViewModel(
            subtitle: rateFormatted,
            priceChange: priceChangeState,
            miniChartPoints: .loading,
            action: { [weak self] in
                self?.openMarketsTokenDetails()
            }
        )
    }
}

// MARK: - SingleTokenNotificationManagerInteractionDelegate

extension TokenDetailsViewModel: SingleTokenNotificationManagerInteractionDelegate {
    func confirmDiscardingUnfulfilledAssetRequirements(
        with configuration: TokenNotificationEvent.UnfulfilledRequirementsConfiguration,
        confirmationAction: @escaping () -> Void
    ) {
        let alertBuilder = AssetRequirementsAlertBuilder()
        alert = alertBuilder.fulfillAssetRequirementsDiscardedAlert(confirmationAction: confirmationAction)
    }
}

// MARK: - BalanceWithButtonsViewModelBalanceProvider

extension TokenDetailsViewModel: BalanceWithButtonsViewModelBalanceProvider {
    var totalCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        walletModel
            .totalTokenBalanceProvider
            .formattedBalanceTypePublisher
    }

    var totalFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        walletModel
            .fiatTotalTokenBalanceProvider
            .formattedBalanceTypePublisher
    }

    var availableCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        walletModel
            .availableBalanceProvider
            .formattedBalanceTypePublisher
    }

    var availableFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        walletModel
            .fiatAvailableBalanceProvider
            .formattedBalanceTypePublisher
    }
}

extension TokenDetailsViewModel: BalanceTypeSelectorProvider {
    var showBalanceSelectorPublisher: AnyPublisher<Bool, Never> {
        func isZeroOrNil(_ cached: TokenBalanceType.Cached?) -> Bool {
            cached?.balance == .zero || cached == nil
        }

        return walletModel.stakingBalanceProvider.balanceTypePublisher.map {
            switch $0 {
            case .empty:
                return false
            case .loaded(let amount) where amount == .zero:
                return false
            case .failure(let cached) where isZeroOrNil(cached),
                 .loading(let cached) where isZeroOrNil(cached):
                return false
            case .failure, .loading, .loaded:
                return true
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - TokenDetailsBalanceDataProvider

extension TokenDetailsViewModel: TokenDetailsBalanceDataProvider {
    var stakingBalanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        walletModel.stakingBalanceProvider.balanceTypePublisher
            .eraseToAnyPublisher()
    }

    var isTokenCustom: Bool {
        walletModel.isCustom
    }
}

// MARK: - TokenDetailsActionsRoutable

extension TokenDetailsViewModel: TokenDetailsActionsRoutable {}

extension TokenDetailsViewModel {
    func makeYieldModuleFlowFactory(manager: YieldModuleManager) -> YieldModuleFlowFactory? {
        // [REDACTED_USERNAME]. Maintain the previous logic. Do not create factory if `multipleTransactionsSender` not found
        guard walletModel.multipleTransactionsSender != nil else {
            return nil
        }

        let factory = WalletModelTransactionDispatcherProvider(walletModel: walletModel, signer: userWalletInfo.signer)
        let dispatcher = factory.makeYieldModuleTransactionDispatcher()

        return CommonYieldModuleFlowFactory(
            walletModel: walletModel,
            yieldModuleManager: manager,
            transactionDispatcher: dispatcher
        )
    }

    func openYieldBalanceInfo() {
        guard let manager = walletModel.yieldModuleManager, let factory = makeYieldModuleFlowFactory(manager: manager) else {
            return
        }

        Analytics.log(
            event: .earningEarnedFundsInfo,
            params: [.token: walletModel.tokenItem.currencySymbol, .blockchain: walletModel.tokenItem.blockchain.displayName]
        )

        coordinator?.openYieldBalanceInfo(factory: factory)
    }
}

extension TokenDetailsViewModel {
    func makeCloreMigrationModuleFlowFactory() -> CloreMigrationModuleFlowFactory? {
        guard let coordinator else { return nil }
        return CommonCloreMigrationModuleFlowFactory(walletModel: walletModel, coordinator: coordinator)
    }

    func openCloreMigration() {
        guard let factory = makeCloreMigrationModuleFlowFactory() else {
            return
        }

        coordinator?.openCloreMigration(factory: factory)
    }
}

// MARK: - YieldModuleStatusProvider

extension TokenDetailsViewModel: YieldModuleStatusProvider {
    var yieldModuleState: AnyPublisher<YieldModuleManagerStateInfo, Never> {
        walletModel.yieldModuleManager?
            .statePublisher
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
            ?? Just(YieldModuleManagerStateInfo(marketInfo: nil, state: .disabled)).eraseToAnyPublisher()
    }
}

// MARK: - RefreshStatusProvider

extension TokenDetailsViewModel: RefreshStatusProvider {
    var isRefreshing: AnyPublisher<Bool, Never> {
        refreshScrollViewStateObject
            .statePublisher
            .map { $0.isRefreshing }
            .eraseToAnyPublisher()
    }
}

extension TokenDetailsViewModel {
    struct DotsMenuItem: Identifiable {
        var id: String { type.rawValue }

        let type: MenuType
        let action: () -> Void

        enum MenuType: String {
            case generateXPUB
            case dynamicAddresses
            case hideToken

            var role: ButtonRole? {
                switch self {
                case .generateXPUB, .dynamicAddresses: .none
                case .hideToken: .destructive
                }
            }

            var title: String {
                switch self {
                case .generateXPUB: Localization.tokenDetailsGenerateXpub
                case .dynamicAddresses: Localization.dynamicAddresses
                case .hideToken: Localization.tokenDetailsHideToken
                }
            }

            var accessibilityIdentifier: String? {
                switch self {
                case .generateXPUB, .dynamicAddresses: .none
                case .hideToken: TokenAccessibilityIdentifiers.hideTokenButton
                }
            }
        }
    }
}
