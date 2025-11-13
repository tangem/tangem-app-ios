//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

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
    @Published var confirmationDialog: ConfirmationDialogViewModel?
    @Published var bannerNotificationInputs: [NotificationViewInput] = []
    @Published var yieldModuleAvailability: YieldModuleAvailability = .checking

    private(set) lazy var balanceWithButtonsModel = BalanceWithButtonsViewModel(
        tokenItem: walletModel.tokenItem,
        buttonsPublisher: $actionButtons.eraseToAnyPublisher(),
        balanceProvider: self,
        balanceTypeSelectorProvider: self,
        yieldModuleStatusProvider: self,
        showYieldBalanceInfoAction: { [weak self] in
            self?.openYieldBalanceInfo()
        },
        reloadBalance: { @MainActor [weak self] in
            await self?.onPullToRefresh()
        }
    )

    private(set) lazy var tokenDetailsHeaderModel: TokenDetailsHeaderViewModel = .init(tokenItem: walletModel.tokenItem)
    @Published private(set) var activeStakingViewData: ActiveStakingViewData?

    private weak var coordinator: TokenDetailsRoutable?
    private let bannerNotificationManager: NotificationManager?
    private let xpubGenerator: XPUBGenerator?
    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()
    private let pendingTransactionDetails: PendingTransactionDetails?
    private var bag = Set<AnyCancellable>()

    var iconUrl: URL? {
        guard let id = walletModel.tokenItem.id else {
            return nil
        }

        return IconURLBuilder().tokenIconURL(id: id)
    }

    var customTokenColor: Color? {
        walletModel.tokenItem.token?.customTokenColor
    }

    var canHideToken: Bool { userWalletModel.config.hasFeature(.multiCurrency) }

    var canGenerateXPUB: Bool { xpubGenerator != nil }

    var hasDotsMenu: Bool { canHideToken || canGenerateXPUB }

    init(
        userWalletModel: UserWalletModel,
        walletModel: any WalletModel,
        notificationManager: NotificationManager,
        bannerNotificationManager: NotificationManager?,
        pendingExpressTransactionsManager: PendingExpressTransactionsManager,
        xpubGenerator: XPUBGenerator?,
        coordinator: TokenDetailsRoutable,
        tokenRouter: SingleTokenRoutable,
        pendingTransactionDetails: PendingTransactionDetails?
    ) {
        self.coordinator = coordinator
        self.bannerNotificationManager = bannerNotificationManager
        self.xpubGenerator = xpubGenerator
        self.pendingTransactionDetails = pendingTransactionDetails

        super.init(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            notificationManager: notificationManager,
            pendingExpressTransactionsManager: pendingExpressTransactionsManager,
            tokenRouter: tokenRouter
        )
        notificationManager.setupManager(with: self)
        bannerNotificationManager?.setupManager(with: self)

        prepareSelf()
    }

    deinit {
        AppLogger.debug("TokenDetailsViewModel deinit")
    }

    func onAppear() {
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

        let params: [Analytics.ParameterKey: String] = [
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.tokenItem.blockchain.displayName,
            .balance: balanceState.rawValue,
        ]

        Analytics.log(event: .detailsScreenOpened, params: params)

        walletModel.yieldModuleManager?.sendActivationState()
    }

    override func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .empty,
             .unlock:
            break
        case .openFeeCurrency:
            openFeeCurrency()
        case .swap:
            openExchange()
        case .generateAddresses,
             .backupCard,
             .buyCrypto,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .addHederaTokenAssociation,
             .retryKaspaTokenTransaction,
             .leaveAmount,
             .openLink,
             .stake,
             .openFeedbackMail,
             .openAppStoreReview,
             .support,
             .openCurrency,
             .seedSupportNo,
             .seedSupportYes,
             .seedSupport2No,
             .seedSupport2Yes,
             .addTokenTrustline,
             .openMobileFinishActivation,
             .openMobileUpgrade,
             .openBuyCrypto,
             .tangemPayCreateAccountAndIssueCard,
             .activate,
             .tangemPayViewKYCStatus,
             .allowPushPermissionRequest,
             .postponePushPermissionRequest,
             .givePermission:
            super.didTapNotification(with: id, action: action)
        }
    }

    override func present(confirmationDialog: ConfirmationDialogViewModel) {
        self.confirmationDialog = confirmationDialog
    }

    override func copyDefaultAddress() {
        super.copyDefaultAddress()
        Analytics.log(event: .buttonCopyAddress, params: [
            .token: walletModel.tokenItem.currencySymbol,
            .source: Analytics.ParameterValue.token.rawValue,
        ])
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
        // accounts_fixes_needed_token_details
        if userWalletModel.userTokensManager.canRemove(walletModel.tokenItem) {
            showHideWarningAlert()
        } else {
            showUnableToHideAlert()
        }
    }

    func generateXPUBButtonAction() {
        guard let xpubGenerator else { return }

        runTask { [weak self] in
            do {
                let xpub = try await xpubGenerator.generateXPUB()
                let viewController = await UIActivityViewController(activityItems: [xpub], applicationActivities: nil)
                AppPresenter.shared.show(viewController)
            } catch {
                let sdkError = error.toTangemSdkError()
                if !sdkError.isUserCancelled {
                    self?.alert = error.alertBinder
                }
            }
        }
    }

    private func showUnableToHideAlert() {
        let tokenName = walletModel.tokenItem.name
        let message = Localization.tokenDetailsUnableHideAlertMessage(
            tokenName,
            currencySymbol,
            blockchain.displayName
        )

        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsUnableHideAlertTitle(tokenName),
            message: message,
            primaryButton: .default(Text(Localization.commonOk))
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

        // accounts_fixes_needed_token_details
        userWalletModel.userTokensManager.remove(walletModel.tokenItem)
        dismiss()
    }
}

// MARK: - Setup functions

private extension TokenDetailsViewModel {
    private func prepareSelf() {
        tokenNotificationInputs = notificationManager.notificationInputs
        bind()
    }

    private func bind() {
        walletModel.yieldModuleManager?.statePublisher
            .compactMap { $0 }
            .filter { $0.state != .loading }
            .receiveOnMain()
            .sink { [weak self] state in
                self?.updateYieldAvailability(state: state)
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

        bannerNotificationManager?.notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.bannerNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        walletModel.stakingManagerStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                AppLogger.info("Token details receive new StakingManager state: \(state)")
                self?.updateStaking(state: state)
            }
            .store(in: &bag)
    }

    private func updateStaking(state: StakingManagerState) {
        switch state {
        case .loading:
            // Do nothing
            break
        case .availableToStake, .notEnabled:
            activeStakingViewData = nil
        case .loadingError, .temporaryUnavailable:
            activeStakingViewData = .init(balance: .loadingError, rewards: .none)
        case .staked(let staked):
            let rewards = mapToRewardsState(staked: staked)
            let balance = mapToStakedBalance(staked: staked)

            activeStakingViewData = ActiveStakingViewData(
                balance: .balance(balance) { [weak self] in self?.openStaking() },
                rewards: rewards
            )
        }
    }

    func mapToRewardsState(staked: StakingManagerState.Staked) -> ActiveStakingViewData.RewardsState? {
        switch (staked.yieldInfo.rewardClaimingType, staked.balances.rewards().sum()) {
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
        yieldModuleAvailability = makeYieldAvailability(state: state.state, marketInfo: state.marketInfo)
    }

    private func makeYieldAvailability(
        state: YieldModuleManagerState,
        marketInfo: YieldModuleMarketInfo?
    ) -> YieldModuleAvailability {
        guard FeatureProvider.isAvailable(.yieldModule),
              let manager = walletModel.yieldModuleManager,
              let factory = makeYieldModuleFlowFactory(manager: manager)
        else {
            return .notApplicable
        }

        func makeEligibleViewModelIfPossible() -> YieldModuleAvailability {
            if let apy = marketInfo?.apy {
                let action = { [weak self] apy in self?.coordinator?.openYieldModulePromoView(apy: apy, factory: factory) }
                let vm = factory.makeYieldAvailableNotificationViewModel(apy: apy, onButtonTap: { apy in action(apy) })
                return .eligible(vm)
            } else {
                return .notApplicable
            }
        }

        switch state {
        case .active(let info):
            let navigationAction = { [weak self] in self?.coordinator?.openYieldModuleActiveInfo(factory: factory) }
            let state: YieldStatusViewModel.State = .active(
                isApproveRequired: info.isAllowancePermissionRequired,
                hasUndepositedAmounts: !info.nonYieldModuleBalanceValue.isZero,
                apy: marketInfo?.apy
            )

            let vm = factory.makeYieldStatusViewModel(state: state, navigationAction: { navigationAction() })

            if info.isAllowancePermissionRequired {
                Analytics.log(
                    event: .earningNoticeApproveNeeded,
                    params: [.token: walletModel.tokenItem.currencySymbol, .blockchain: walletModel.tokenItem.blockchain.displayName]
                )
            }

            return .active(vm)

        case .notActive:
            return makeEligibleViewModelIfPossible()

        case .processing(let action):
            let state: YieldStatusViewModel.State = action == .enter ? .loading : .closing
            let vm = factory.makeYieldStatusViewModel(state: state, navigationAction: {})
            return (action == .enter) ? .enter(vm) : .exit(vm)

        case .disabled:
            return .notApplicable

        case .loading:
            AppLogger.warning("Loading state should not be passed here to avoid blinking on UI")
            return .notApplicable

        case .failedToLoad(_, .some(let cachedState)):
            return makeYieldAvailability(state: cachedState, marketInfo: marketInfo)

        case .failedToLoad:
            return makeEligibleViewModelIfPossible()
        }
    }
}

// MARK: - Navigation functions

private extension TokenDetailsViewModel {
    func dismiss() {
        coordinator?.dismiss()
    }

    func openFeeCurrency() {
        // accounts_fixes_needed_token_details
        guard let feeCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem == walletModel.feeTokenItem
        }) else {
            assertionFailure("Fee currency '\(walletModel.feeTokenItem.name)' for currency '\(walletModel.tokenItem.name)' not found")
            return
        }

        coordinator?.openFeeCurrency(for: feeCurrencyWalletModel, userWalletModel: userWalletModel)
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
    var shouldShowBalanceSelector: Bool {
        switch walletModel.stakingBalanceProvider.balanceType {
        case .empty:
            return false
        case .loaded(let amount) where amount == .zero:
            return false
        case .failure(let cached) where cached?.balance == .zero || cached == nil:
            return false
        case .failure, .loading, .loaded:
            return true
        }
    }
}

extension TokenDetailsViewModel {
    func makeYieldModuleFlowFactory(manager: YieldModuleManager) -> YieldModuleFlowFactory? {
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
