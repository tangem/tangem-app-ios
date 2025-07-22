//
//  SingleTokenBaseViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk
import TangemFoundation
import TangemStories
import TangemLocalization
import TangemUI
import struct TangemUIUtils.ActionSheetBinder
import struct TangemUIUtils.AlertBinder

class SingleTokenBaseViewModel: NotificationTapDelegate {
    @Injected(\.storyAvailabilityService) private var storyAvailabilityService: any StoryAvailabilityService

    @Published var alert: AlertBinder? = nil
    @Published var transactionHistoryState: TransactionsListView.State = .loading
    @Published var isReloadingTransactionHistory: Bool = false
    @Published var isFulfillingAssetRequirements = false
    @Published var actionButtons: [FixedSizeButtonWithIconInfo] = []
    @Published var tokenNotificationInputs: [NotificationViewInput] = []
    @Published var pendingExpressTransactions: [PendingExpressTransactionView.Info] = []
    @Published private(set) var pendingTransactionViews: [TransactionViewModel] = []
    @Published private(set) var miniChartData: LoadingValue<[Double]?> = .loading

    let notificationManager: NotificationManager
    let userWalletModel: UserWalletModel
    let walletModel: any WalletModel

    var availableActions: [TokenActionType] = []

    private let tokenRouter: SingleTokenRoutable
    private let priceFormatter = MarketsTokenPriceFormatter()
    private let tokenActionAvailabilityAlertBuilder = TokenActionAvailabilityAlertBuilder()
    private let tokenActionAvailabilityAnalyticsMapper = TokenActionAvailabilityAnalyticsMapper()
    private let tokenActionAvailabilityProvider: TokenActionAvailabilityProvider
    private let pendingExpressTransactionsManager: PendingExpressTransactionsManager

    private var priceChangeFormatter = PriceChangeFormatter()
    private var transactionHistoryBag: AnyCancellable?
    private var updateSubscription: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    var blockchainNetwork: BlockchainNetwork { walletModel.tokenItem.blockchainNetwork }

    var amountType: Amount.AmountType { walletModel.tokenItem.amountType }

    var rateFormatted: String {
        priceFormatter.formatPrice(walletModel.quote?.price)
    }

    var priceChangeState: TokenPriceChangeView.State {
        guard let change = walletModel.quote?.priceChange24h else {
            return .noData
        }

        let result = priceChangeFormatter.formatPercentValue(change, option: .priceChange)
        return .loaded(signType: result.signType, text: result.formattedText)
    }

    var blockchain: Blockchain { blockchainNetwork.blockchain }

    var currencySymbol: String {
        amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
    }

    var isMarketsDetailsAvailable: Bool {
        walletModel.tokenItem.id != nil
    }

    lazy var transactionHistoryMapper = TransactionHistoryMapper(currencySymbol: currencySymbol, walletAddresses: walletModel.addresses.map { $0.value }, showSign: true)
    lazy var pendingTransactionRecordMapper = PendingTransactionRecordMapper(formatter: BalanceFormatter())
    lazy var miniChartsProvider = MarketsListChartsHistoryProvider()

    private let miniChartPriceIntervalType = MarketsPriceIntervalType.day

    init(
        userWalletModel: UserWalletModel,
        walletModel: any WalletModel,
        notificationManager: NotificationManager,
        pendingExpressTransactionsManager: PendingExpressTransactionsManager,
        tokenRouter: SingleTokenRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
        tokenActionAvailabilityProvider = TokenActionAvailabilityProvider(
            userWalletConfig: userWalletModel.config,
            walletModel: walletModel
        )
        self.notificationManager = notificationManager
        self.pendingExpressTransactionsManager = pendingExpressTransactionsManager
        self.tokenRouter = tokenRouter

        prepareSelf()
    }

    func presentActionSheet(_ actionSheet: ActionSheetBinder) {
        assertionFailure("Must be reimplemented")
    }

    func openExplorer() {
        let addresses = walletModel.addresses

        if addresses.count == 1 {
            openAddressExplorer(at: 0)
        } else {
            openAddressSelector(addresses) { [weak self] index in
                self?.openAddressExplorer(at: index)
            }
        }
    }

    func openTransactionExplorer(transaction hash: String) {
        guard let url = walletModel.exploreTransactionURL(for: hash) else {
            return
        }

        openExplorer(at: url)
    }

    func fetchMoreHistory() -> FetchMore? {
        // flag isReloadingTransactionHistory need for locked fetchMore requests update transaction history, when pullToRefresh is active
        guard walletModel.canFetchHistory, !isReloadingTransactionHistory else {
            return nil
        }

        return FetchMore { [weak self] in
            self?.performLoadHistory()
        }
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        guard updateSubscription == nil else {
            return
        }

        if let id = walletModel.tokenItem.currencyId, miniChartsProvider.items.isEmpty {
            miniChartsProvider.fetch(for: [id], with: miniChartPriceIntervalType)
        }

        isReloadingTransactionHistory = true
        updateSubscription = walletModel.generalUpdate(silent: false)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                guard let self else {
                    return
                }

                AppLogger.info(self, "♻️ loading state changed")
                isReloadingTransactionHistory = false
                updateSubscription = nil
                completionHandler()
            })
    }

    /// This method should be overridden to send analytics events for navigation.
    /// Please check `SingleWalletMainContentViewModel` and `TokenDetailsViewModel`
    func openMarketsTokenDetails() {
        tokenRouter.openMarketsTokenDetails(for: walletModel.tokenItem)
    }

    func onButtonReloadHistory() {
        Analytics.log(event: .buttonReload, params: [.token: currencySymbol])

        // We should reset transaction history to initial state here
        walletModel.clearHistory()

        DispatchQueue.main.async {
            self.isReloadingTransactionHistory = true
        }

        performLoadHistory()
    }

    func copyDefaultAddress() {
        UIPasteboard.general.string = walletModel.defaultAddressString
        let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        heavyImpactGenerator.impactOccurred()
    }

    /// We need to keep this not in extension because we may want to override this logic and
    /// implementation from extensions can't be overridden
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .buyCrypto:
            openBuyCrypto()
        case .addHederaTokenAssociation, .addTokenTrustline:
            fulfillAssetRequirements(with: .buttonAddTokenTrustline)
        case .retryKaspaTokenTransaction:
            fulfillAssetRequirements(with: .tokenButtonRevealTryAgain)
        case .stake:
            openStaking()
        case .empty:
            break
        default:
            break
        }
    }

    private func performLoadHistory() {
        transactionHistoryBag = walletModel
            .updateTransactionsHistory()
            .receive(on: DispatchQueue.main)
            .receiveCompletion { [weak self] _ in
                self?.isReloadingTransactionHistory = false
            }
    }

    private func fulfillAssetRequirements(with analyticsEvent: Analytics.Event) {
        func sendAnalytics(isSuccessful: Bool) {
            let status: Analytics.ParameterValue = isSuccessful ? .sent : .error

            Analytics.log(
                event: analyticsEvent,
                params: [
                    .token: walletModel.tokenItem.currencySymbol,
                    .blockchain: blockchain.displayName,
                    .status: status.rawValue,
                ]
            )
        }

        isFulfillingAssetRequirements = true
        let alertBuilder = AssetRequirementsAlertBuilder()
        let requirementsCondition = walletModel.assetRequirementsManager?.requirementsCondition(for: amountType)

        // If the user doesn't meet the requirements to proceed (e.g. insufficient base coin or token),
        // show an alert explaining the issue.
        if let fulfillAssetRequirementsAlert = alertBuilder.fulfillAssetRequirementsAlert(
            for: requirementsCondition,
            feeTokenItem: walletModel.feeTokenItem,
            hasFeeCurrency: walletModel.assetRequirementsManager?.hasSufficientFeeBalance(
                for: requirementsCondition,
                on: walletModel.tokenItem.amountType
            ) ?? false
        ) {
            sendAnalytics(isSuccessful: false)
            isFulfillingAssetRequirements = false
            alert = fulfillAssetRequirementsAlert

            return
        }

        sendAnalytics(isSuccessful: true)

        walletModel
            .fulfillRequirements(signer: userWalletModel.signer)
            .materialize()
            .failures()
            .withWeakCaptureOf(self)
            .map { viewModel, error in
                let alertBuilder = AssetRequirementsAlertBuilder()
                let networkName = viewModel.blockchain.displayName

                viewModel.isFulfillingAssetRequirements = false
                return alertBuilder.fulfillmentAssetRequirementsFailedAlert(error: error, networkName: networkName)
            }
            .assign(to: \.alert, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - Setup functions

extension SingleTokenBaseViewModel {
    private func prepareSelf() {
        bind()
        setupActionButtons()
        setupMiniChart()
        updateActionButtons()
        performLoadHistory()
    }

    private func setupActionButtons() {
        availableActions = tokenActionAvailabilityProvider.buildAvailableButtonsList()

        if isButtonDisabled(with: .exchange) {
            Analytics.log(event: .tokenActionButtonDisabled, params: [
                .token: walletModel.tokenItem.currencySymbol,
                .blockchain: walletModel.tokenItem.blockchain.displayName,
                .action: Analytics.ParameterValue.swap.rawValue,
                .status: tokenActionAvailabilityAnalyticsMapper.mapToParameterValue(tokenActionAvailabilityProvider.swapAvailability).rawValue,
            ])
        }
    }

    private func bind() {
        walletModel.totalTokenBalanceProvider
            .balanceTypePublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .filter { !$0.isLoading }
            .receiveValue { [weak self] newState in
                AppLogger.info(self, "Token details receive new wallet model state: \(newState)")
                self?.updateActionButtons()
            }
            .store(in: &bag)

        walletModel
            .pendingTransactionPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .map { owner, transactions in
                // Only if the transaction history isn't supported
                guard !owner.walletModel.isSupportedTransactionHistory else {
                    return []
                }

                return transactions.map { transaction in
                    owner.pendingTransactionRecordMapper.mapToTransactionViewModel(transaction)
                }
            }
            .withWeakCaptureOf(self)
            .sink { owner, viewModels in
                owner.pendingTransactionViews = viewModels
            }
            .store(in: &bag)

        walletModel.transactionHistoryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                AppLogger.info(self, "New transaction history state: \(newState)")
                self?.updateHistoryState(to: newState)
            }
            .store(in: &bag)

        notificationManager.notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            // Fix for reappearing banner notifications.
            // [REDACTED_TODO_COMMENT]
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .assign(to: \.tokenNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        walletModel.actionsUpdatePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.updateActionButtons()
            }
            .store(in: &bag)

        pendingExpressTransactionsManager
            .pendingTransactionsPublisher
            .map {
                $0.filter { transaction in
                    // Don't show onramp's transaction with this statuses for SingleWallet and TokenDetails
                    switch transaction.type {
                    case .onramp:
                        return ![.created, .canceled, .paused].contains(transaction.transactionStatus)
                    case .swap:
                        return true
                    }
                }
            }
            .map { [weak self] transactions in
                PendingExpressTransactionsConverter()
                    .convertToTokenDetailsPendingTxInfo(transactions) { [weak self] id in
                        self?.didTapPendingExpressTransaction(id: id)
                    }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.pendingExpressTransactions, on: self, ownership: .weak)
            .store(in: &bag)

        storyAvailabilityService
            .availableStoriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateActionButtons()
            }
            .store(in: &bag)
    }

    private func setupMiniChart() {
        guard let id = walletModel.tokenItem.currencyId else {
            miniChartData = .failedToLoad(error: "")
            return
        }
        miniChartsProvider.fetch(for: [id], with: miniChartPriceIntervalType)

        miniChartsProvider.$items
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .compactMap { viewModel, items in
                items[id]?[viewModel.miniChartPriceIntervalType]
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, chartsData in
                viewModel.updateMiniChartState(using: chartsData)
            }
            .store(in: &bag)
    }

    private func updateActionButtons() {
        let buttons = availableActions.map { type in
            let isDisabled = isButtonDisabled(with: type)
            let showBadge = shouldShowUnreadNotificationBadge(for: type) && !isDisabled

            return FixedSizeButtonWithIconInfo(
                title: type.title,
                icon: type.icon,
                disabled: false,
                style: isDisabled ? .disabled : .default,
                shouldShowBadge: showBadge,
                action: { [weak self] in
                    self?.action(for: type)?()
                },
                longPressAction: longTapAction(for: type)
            )
        }

        actionButtons = buttons.sorted(by: { lhs, rhs in
            if lhs.style != .disabled, rhs.style != .disabled {
                return false
            }

            return lhs.style != .disabled
        })
    }

    private func updateHistoryState(to newState: WalletModelTransactionHistoryState) {
        switch newState {
        case .notSupported:
            transactionHistoryState = .notSupported
        case .notLoaded:
            transactionHistoryState = .loading
        case .loading:
            if case .notLoaded = newState {
                transactionHistoryState = .loading
            }
        case .error(let error):
            transactionHistoryState = .error(error)
        case .loaded(let records):
            let listItems = transactionHistoryMapper.mapTransactionListItem(from: records)
            transactionHistoryState = .loaded(listItems)
        }
    }

    private func updateMiniChartState(using data: MarketsChartModel) {
        do {
            let mapper = MarketsTokenHistoryChartMapper()

            let chartPoints = try mapper
                .mapAndSortValues(from: data)
                .map(\.price.doubleValue)
            miniChartData = .loaded(chartPoints)
        } catch {
            AppLogger.error(error: error)
            miniChartData = .failedToLoad(error: error)
        }
    }

    private func isButtonDisabled(with type: TokenActionType) -> Bool {
        switch type {
        case .buy:
            return !tokenActionAvailabilityProvider.isBuyAvailable
        case .send:
            return !tokenActionAvailabilityProvider.isSendAvailable
        case .receive:
            return !tokenActionAvailabilityProvider.isReceiveAvailable
        case .exchange:
            return !tokenActionAvailabilityProvider.isSwapAvailable
        case .sell:
            return !tokenActionAvailabilityProvider.isSellAvailable
        case .copyAddress, .hide, .stake, .marketsDetails:
            return true
        }
    }

    private func shouldShowUnreadNotificationBadge(for type: TokenActionType) -> Bool {
        switch type {
        case .exchange:
            storyAvailabilityService.checkStoryAvailability(storyId: .swap)
        default:
            false
        }
    }

    private func action(for buttonType: TokenActionType) -> (() -> Void)? {
        switch buttonType {
        case .buy: return openBuyCryptoAction
        case .send: return openSendAction
        case .receive: return openReceiveAction
        case .exchange: return openExchangeAction
        case .sell: return openSellAction
        case .copyAddress, .hide, .stake, .marketsDetails: return nil
        }
    }

    private func longTapAction(for buttonType: TokenActionType) -> (() -> Void)? {
        switch buttonType {
        case .receive:
            return weakify(self, forFunction: SingleTokenBaseViewModel.copyDefaultAddress)
        case .buy, .send, .exchange, .sell, .copyAddress, .hide, .stake, .marketsDetails:
            return nil
        }
    }
}

// MARK: - Navigation

extension SingleTokenBaseViewModel {
    func openReceive() {
        if let receiveUnavailableAlert = tokenActionAvailabilityAlertBuilder.alert(for: tokenActionAvailabilityProvider.receiveAvailablity) {
            alert = receiveUnavailableAlert
            return
        }

        tokenRouter.openReceive(walletModel: walletModel)
    }

    func openBuyCrypto() {
        if let buyUnavailableAlert = tokenActionAvailabilityAlertBuilder.alert(for: tokenActionAvailabilityProvider.buyAvailablity) {
            alert = buyUnavailableAlert
            return
        }

        if FeatureProvider.isAvailable(.onramp) {
            tokenRouter.openOnramp(walletModel: walletModel)
        } else {
            tokenRouter.openBuy(walletModel: walletModel)
        }
    }

    func openSend() {
        if let sendUnavailableAlert = tokenActionAvailabilityAlertBuilder.alert(for: tokenActionAvailabilityProvider.sendAvailability) {
            alert = sendUnavailableAlert
            return
        }

        tokenRouter.openSend(walletModel: walletModel)
    }

    func openExchange() {
        if let swapUnavailableAlert = tokenActionAvailabilityAlertBuilder.alert(for: tokenActionAvailabilityProvider.swapAvailability) {
            alert = swapUnavailableAlert
            return
        }

        tokenRouter.openExchange(walletModel: walletModel)
    }

    func openStaking() {
        tokenRouter.openStaking(walletModel: walletModel)
    }

    func openSell() {
        if let sellUnavailableAlert = tokenActionAvailabilityAlertBuilder.alert(for: tokenActionAvailabilityProvider.sellAvailability) {
            alert = sellUnavailableAlert
            return
        }

        tokenRouter.openSell(for: walletModel)
    }

    func openSendToSell(with request: SellCryptoRequest) {
        tokenRouter.openSendToSell(with: request, for: walletModel)
    }

    func openAddressSelector(_ addresses: [BlockchainSdk.Address], callback: @escaping (Int) -> Void) {
        if addresses.isEmpty {
            return
        }

        let addressButtons: [Alert.Button] = addresses.enumerated().map { index, address in
            .default(Text(address.localizedName)) {
                callback(index)
            }
        }

        let sheet = ActionSheet(
            title: Text(Localization.tokenDetailsChooseAddress),
            buttons: addressButtons + [.cancel(Text(Localization.commonCancel))]
        )
        presentActionSheet(ActionSheetBinder(sheet: sheet))
    }

    func openExplorer(at url: URL) {
        tokenRouter.openExplorer(at: url, for: walletModel)
    }

    func didTapPendingExpressTransaction(id: String) {
        let transactions = pendingExpressTransactionsManager.pendingTransactions

        guard let transaction = transactions.first(where: { $0.expressTransactionId == id }) else {
            return
        }

        tokenRouter.openPendingExpressTransactionDetails(
            pendingTransaction: transaction,
            tokenItem: walletModel.tokenItem,
            pendingTransactionsManager: pendingExpressTransactionsManager
        )
    }

    private func openAddressExplorer(at index: Int) {
        guard let url = walletModel.exploreURL(for: index, token: amountType.token) else {
            return
        }

        openExplorer(at: url)
    }

    private func openExchangeAction() {
        Analytics.log(event: .buttonExchange, params: [
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.tokenItem.blockchain.displayName,
            .action: Analytics.ParameterValue.swap.rawValue,
            .status: tokenActionAvailabilityAnalyticsMapper.mapToParameterValue(tokenActionAvailabilityProvider.swapAvailability).rawValue,
        ])

        openExchange()
    }

    private func openBuyCryptoAction() {
        Analytics.log(event: .buttonBuy, params: [
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.tokenItem.blockchain.displayName,
            .action: Analytics.ParameterValue.buy.rawValue,
            .status: tokenActionAvailabilityAnalyticsMapper.mapToParameterValue(tokenActionAvailabilityProvider.buyAvailablity).rawValue,
        ])

        openBuyCrypto()
    }

    private func openSellAction() {
        Analytics.log(event: .buttonSell, params: [
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.tokenItem.blockchain.displayName,
            .action: Analytics.ParameterValue.sell.rawValue,
            .status: tokenActionAvailabilityAnalyticsMapper.mapToParameterValue(tokenActionAvailabilityProvider.sellAvailability).rawValue,
        ])

        openSell()
    }

    private func openSendAction() {
        Analytics.log(event: .buttonSend, params: [
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.tokenItem.blockchain.displayName,
            .action: Analytics.ParameterValue.send.rawValue,
            .status: tokenActionAvailabilityAnalyticsMapper.mapToParameterValue(tokenActionAvailabilityProvider.sendAvailability).rawValue,
        ])

        openSend()
    }

    private func openReceiveAction() {
        Analytics.log(event: .buttonReceive, params: [
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.tokenItem.blockchain.displayName,
            .action: Analytics.ParameterValue.receive.rawValue,
            .status: tokenActionAvailabilityAnalyticsMapper.mapToParameterValue(tokenActionAvailabilityProvider.receiveAvailablity).rawValue,
        ])

        openReceive()
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension SingleTokenBaseViewModel: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "WalletModel": walletModel.description,
            ]
        )
    }
}
