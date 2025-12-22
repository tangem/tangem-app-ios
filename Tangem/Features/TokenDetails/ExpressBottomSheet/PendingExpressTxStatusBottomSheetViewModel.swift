//
//  PendingExpressTxStatusBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import TangemExpress
import TangemLocalization
import TangemFoundation
import struct TangemUI.TokenIconInfo
import struct TangemUIUtils.AlertBinder

class PendingExpressTxStatusBottomSheetViewModel: ObservableObject, Identifiable {
    var transactionID: String? {
        pendingTransaction.externalTxId
    }

    var animationDuration: TimeInterval {
        Constants.animationDuration
    }

    let sheetTitle: String
    let statusViewTitle: String

    let timeString: String
    let sourceTokenIconInfo: TokenIconInfo
    let destinationTokenIconInfo: TokenIconInfo
    let sourceAmountText: String
    let destinationAmountText: String

    @Published var providerRowViewModel: ProviderRowViewModel
    @Published var sourceFiatAmountTextState: LoadableTextView.State = .loading
    @Published var destinationFiatAmountTextState: LoadableTextView.State = .loading
    @Published var statusesList: [PendingExpressTxStatusRow.StatusRowData] = []
    @Published var currentStatusIndex = 0
    @Published var showGoToProviderHeaderButton = true
    @Published var notificationViewInputs: [NotificationViewInput] = []
    @Published var hideTransactionAlert: AlertBinder?

    @Published private(set) var isHideButtonShowed = false

    private let expressProviderFormatter = ExpressProviderFormatter(balanceFormatter: .init())
    private weak var pendingTransactionsManager: (any PendingExpressTransactionsManager)?

    private let pendingTransaction: PendingTransaction
    private let currentTokenItem: TokenItem
    private let userWalletInfo: UserWalletInfo

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()

    private var subscription: AnyCancellable?
    private var notificationUpdateWorkItem: DispatchWorkItem?
    private weak var router: PendingExpressTxStatusRoutable?
    private var externalProviderTxURL: URL? {
        pendingTransaction.externalTxURL.flatMap { URL(string: $0) }
    }

    private var alreadyTrackedTokenNoticeLongTimeTransactionEvent: Bool = false

    init(
        pendingTransaction: PendingTransaction,
        currentTokenItem: TokenItem,
        userWalletInfo: UserWalletInfo,
        pendingTransactionsManager: PendingExpressTransactionsManager,
        router: PendingExpressTxStatusRoutable
    ) {
        self.pendingTransaction = pendingTransaction
        self.currentTokenItem = currentTokenItem
        self.userWalletInfo = userWalletInfo
        self.pendingTransactionsManager = pendingTransactionsManager
        self.router = router

        let provider = pendingTransaction.provider
        let iconBuilder = TokenIconInfoBuilder()

        switch pendingTransaction.type {
        case .swap(let source, let destination):
            sheetTitle = Localization.expressExchangeStatusTitle
            statusViewTitle = Localization.expressExchangeBy(provider.name)
            sourceAmountText = balanceFormatter.formatCryptoBalance(source.amount, currencyCode: source.tokenItem.currencySymbol)
            destinationAmountText = balanceFormatter.formatCryptoBalance(destination.amount, currencyCode: destination.tokenItem.currencySymbol)
            sourceTokenIconInfo = iconBuilder.build(from: source.tokenItem, isCustom: source.isCustom)
            destinationTokenIconInfo = iconBuilder.build(from: destination.tokenItem, isCustom: destination.isCustom)
        case .onramp(let sourceAmount, let sourceCurrencySymbol, let destination):
            sheetTitle = Localization.commonTransactionStatus
            statusViewTitle = Localization.commonTransactionStatus
            sourceAmountText = balanceFormatter.formatFiatBalance(sourceAmount, currencyCode: sourceCurrencySymbol)
            if destination.amount > 0 {
                destinationAmountText = balanceFormatter.formatCryptoBalance(destination.amount, currencyCode: destination.tokenItem.currencySymbol)
            } else {
                destinationAmountText = destination.tokenItem.currencySymbol
            }
            sourceTokenIconInfo = iconBuilder.build(from: sourceCurrencySymbol)
            destinationTokenIconInfo = iconBuilder.build(from: destination.tokenItem, isCustom: destination.isCustom)
        }

        providerRowViewModel = .init(
            provider: expressProviderFormatter.mapToProvider(provider: provider),
            titleFormat: .name,
            isDisabled: false,
            badge: .none,
            subtitles: [.text(Localization.expressFloatingRate)],
            detailsType: .none
        )

        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        timeString = dateFormatter.string(from: pendingTransaction.date)

        loadEmptyFiatRates()
        updateUI(with: pendingTransaction, delay: 0)
        bind()
    }

    func onAppear() {
        var params: [Analytics.ParameterKey: String] = [
            .token: currentTokenItem.currencySymbol,
            .provider: pendingTransaction.provider.name,
        ]

        switch pendingTransaction.type {
        case .onramp(_, let currency, _):
            params[.currency] = currency
            Analytics.log(event: .onrampOnrampStatusOpened, params: params)

            if pendingTransaction.transactionStatus == .verificationRequired {
                Analytics.log(event: .onrampNoticeKYC, params: params)
            }

        case .swap:
            Analytics.log(event: .tokenSwapStatusScreenOpened, params: params)
        }
    }

    func openProviderFromStatusHeader() {
        let params: [Analytics.ParameterKey: String] = [
            .token: currentTokenItem.currencySymbol,
            .provider: pendingTransaction.provider.name,
            .place: Analytics.ParameterValue.status.rawValue,
        ]

        switch pendingTransaction.type {
        case .onramp:
            Analytics.log(event: .onrampButtonGoToProvider, params: params)
        case .swap:
            Analytics.log(event: .tokenButtonGoToProvider, params: params)
        }

        openProvider()
    }

    private func openProvider() {
        guard let url = externalProviderTxURL else {
            return
        }

        router?.openURL(url)
    }

    private func openCurrency(tokenItem: TokenItem) {
        Analytics.log(.tokenButtonGoToToken)
        assert(tokenItem.blockchainNetwork.derivationPath != nil)

        let feeCurrencyFinderResult = try? WalletModelFinder
            .findWalletModel(userWalletId: userWalletInfo.id, tokenItem: tokenItem)

        guard let feeCurrencyFinderResult else {
            return
        }

        router?.openRefundCurrency(
            walletModel: feeCurrencyFinderResult.walletModel,
            userWalletModel: feeCurrencyFinderResult.userWalletModel
        )
    }

    private func loadEmptyFiatRates() {
        switch pendingTransaction.type {
        case .swap(let source, let destination):
            loadRatesIfNeeded(stateKeyPath: \.sourceFiatAmountTextState, for: source, on: self)
            loadRatesIfNeeded(stateKeyPath: \.destinationFiatAmountTextState, for: destination, on: self)
        case .onramp(_, _, let destination):
            sourceFiatAmountTextState = .noData
            if destination.amount > 0 {
                loadRatesIfNeeded(stateKeyPath: \.destinationFiatAmountTextState, for: destination, on: self)
            } else {
                destinationFiatAmountTextState = .noData
            }
        }
    }

    private func loadRatesIfNeeded(
        stateKeyPath: ReferenceWritableKeyPath<PendingExpressTxStatusBottomSheetViewModel, LoadableTextView.State>,
        for tokenTxInfo: ExpressPendingTransactionRecord.TokenTxInfo,
        on root: PendingExpressTxStatusBottomSheetViewModel
    ) {
        guard let currencyId = tokenTxInfo.tokenItem.currencyId else {
            root[keyPath: stateKeyPath] = .noData
            return
        }

        if let fiat = balanceConverter.convertToFiat(tokenTxInfo.amount, currencyId: currencyId) {
            root[keyPath: stateKeyPath] = .loaded(text: balanceFormatter.formatFiatBalance(fiat))
            return
        }

        Task { [weak root] in
            guard let root = root else { return }

            let fiatAmount = try await root.balanceConverter.convertToFiat(tokenTxInfo.amount, currencyId: currencyId)
            let formattedFiat = root.balanceFormatter.formatFiatBalance(fiatAmount)
            await runOnMain {
                root[keyPath: stateKeyPath] = .loaded(text: formattedFiat)
            }
        }
    }

    private func bind() {
        subscription = pendingTransactionsManager?.pendingTransactionsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, pendingTransactions in
                guard let first = pendingTransactions.first(where: { tx in
                    tx.expressTransactionId == viewModel.pendingTransaction.expressTransactionId
                }) else {
                    return (viewModel, nil)
                }

                return (viewModel, first)
            }
            .receive(on: DispatchQueue.main)
            .sink { (viewModel: PendingExpressTxStatusBottomSheetViewModel, pendingTx: PendingTransaction?) in
                // If we've failed to find this transaction in manager it means that it was finished in either way on the provider side
                // We can remove subscription and just display final state of transaction
                guard let pendingTx else {
                    viewModel.subscription = nil
                    return
                }

                // We will hide it via separate notification in case of refunded token
                if pendingTx.transactionStatus.isCanBeHideAutomatically, pendingTx.refundedTokenItem == nil {
                    viewModel.hidePendingTx(expressTransactionId: pendingTx.expressTransactionId)
                }

                viewModel.updateUI(with: pendingTx, delay: Constants.notificationAnimationDelay)
            }
    }

    private func hidePendingTx(expressTransactionId: String) {
        pendingTransactionsManager?.hideTransaction(with: expressTransactionId)
    }

    private func updateUI(with pendingTransaction: PendingTransaction, delay: TimeInterval) {
        let converter = PendingExpressTransactionsConverter()
        let (list, currentIndex) = converter.convertToStatusRowDataList(for: pendingTransaction)

        updateUI(
            provider: pendingTransaction.provider,
            statusesList: list,
            currentIndex: currentIndex,
            currentStatus: pendingTransaction.transactionStatus,
            refundedTokenItem: pendingTransaction.refundedTokenItem,
            hasExternalURL: pendingTransaction.externalTxURL != nil,
            delay: delay
        )
    }

    private func updateUI(
        provider: ExpressPendingTransactionRecord.Provider,
        statusesList: [PendingExpressTxStatusRow.StatusRowData],
        currentIndex: Int,
        currentStatus: PendingExpressTransactionStatus,
        refundedTokenItem: TokenItem?,
        hasExternalURL: Bool,
        delay: TimeInterval
    ) {
        self.statusesList = statusesList
        currentStatusIndex = currentIndex

        let notificationFactory = NotificationsFactory()

        var inputs: [NotificationViewInput] = []

        switch currentStatus {
        case .failed:
            showGoToProviderHeaderButton = false

            if hasExternalURL {
                let input = notificationFactory.buildNotificationInput(
                    for: ExpressNotificationEvent.cexOperationFailed,
                    buttonAction: weakify(self, forFunction: PendingExpressTxStatusBottomSheetViewModel.didTapNotification(with:action:))
                )

                inputs.append(input)
            }

        case .verificationRequired:
            showGoToProviderHeaderButton = false
            let input = notificationFactory.buildNotificationInput(
                for: ExpressNotificationEvent.verificationRequired,
                buttonAction: weakify(self, forFunction: PendingExpressTxStatusBottomSheetViewModel.didTapNotification(with:action:))
            )

            inputs.append(input)

        case .expired:
            showGoToProviderHeaderButton = false

        default:
            showGoToProviderHeaderButton = externalProviderTxURL != nil
        }

        enrichNotificationsWithLongTimeExchangeNotificationIfNeeded(
            providerType: provider.type,
            providerName: provider.name,
            for: currentStatus,
            inputs: &inputs,
            notificationFactory: notificationFactory
        )

        if let refundedTokenItem {
            let input = notificationFactory.buildNotificationInput(
                for: ExpressNotificationEvent.refunded(tokenItem: refundedTokenItem),
                buttonAction: { [weak self] id, action in
                    self?.didTapNotification(with: id, action: action)
                }
            )

            inputs.append(input)
        }

        updateHideButtonState(txStatus: currentStatus)

        scheduleNotificationUpdate(inputs, delay: delay)
    }

    private func scheduleNotificationUpdate(_ newInputs: [NotificationViewInput], delay: TimeInterval) {
        notificationUpdateWorkItem?.cancel()
        notificationUpdateWorkItem = nil

        notificationUpdateWorkItem = DispatchWorkItem(block: { [weak self] in
            self?.notificationViewInputs = newInputs
        })

        // We need to delay notification appearance/disappearance animations
        // to prevent glitches while updating other views (labels, icons, etc.)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: notificationUpdateWorkItem!)
    }

    /// Show long time exchange notification if needed for active exchange state
    private func enrichNotificationsWithLongTimeExchangeNotificationIfNeeded(
        providerType: ExpressPendingTransactionRecord.ProviderType,
        providerName: String,
        for currentStatus: PendingExpressTransactionStatus,
        inputs: inout [NotificationViewInput],
        notificationFactory: NotificationsFactory
    ) {
        guard
            providerType == .cex,
            currentStatus.isProcessingExchange,
            let createdAt = pendingTransaction.createdAt
        else {
            return
        }

        // Check the current swap transaction has already taken more than 15 minutes
        let fifteenMinutes: TimeInterval = 15 * 60
        if Date().timeIntervalSince(createdAt) > fifteenMinutes {
            let input = notificationFactory.buildNotificationInput(
                for: ExpressNotificationEvent.longTimeAverageDuration,
                buttonAction: weakify(self, forFunction: PendingExpressTxStatusBottomSheetViewModel.didTapNotification(with:action:))
            )

            if !alreadyTrackedTokenNoticeLongTimeTransactionEvent {
                let analyticsParams: [Analytics.ParameterKey: String] = [
                    .token: currentTokenItem.currencySymbol,
                    .provider: providerName,
                ]

                Analytics.log(event: .tokenNoticeLongTimeTransaction, params: analyticsParams)

                alreadyTrackedTokenNoticeLongTimeTransactionEvent = true
            }

            inputs.append(input)
        }
    }
}

extension PendingExpressTxStatusBottomSheetViewModel {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        guard let notificationViewInput = notificationViewInputs.first(where: { $0.id == id }),
              let event = notificationViewInput.settings.event as? ExpressNotificationEvent else {
            return
        }

        let isOnramp = pendingTransaction.type.branch == .onramp

        switch event {
        case .verificationRequired:
            Analytics.log(
                event: isOnramp ? .onrampButtonGoToProvider : .tokenButtonGoToProvider,
                params: [
                    .token: currentTokenItem.currencySymbol,
                    .place: Analytics.ParameterValue.kyc.rawValue,
                ]
            )

            openProvider()

        case .longTimeAverageDuration:
            Analytics.log(
                event: isOnramp ? .onrampButtonGoToProvider : .tokenButtonGoToProvider,
                params: [
                    .token: currentTokenItem.currencySymbol,
                    .place: Analytics.ParameterValue.longTime.rawValue,
                ]
            )

            openProvider()

        case .cexOperationFailed:
            Analytics.log(
                event: isOnramp ? .onrampButtonGoToProvider : .tokenButtonGoToProvider,
                params: [
                    .token: currentTokenItem.currencySymbol,
                    .place: Analytics.ParameterValue.fail.rawValue,
                ]
            )

            openProvider()

        case .refunded(let tokenItem):
            openCurrency(tokenItem: tokenItem)

        default:
            break
        }
    }
}

// MARK: - Hide transaction manually

extension PendingExpressTxStatusBottomSheetViewModel {
    func showHideTransactionAlert() {
        hideTransactionAlert = .init(
            alert: .init(
                title: .init(Localization.expressStatusHideDialogTitle),
                message: .init(Localization.expressStatusHideDialogText),
                primaryButton: .default(.init(Localization.commonCancel), action: { [weak self] in self?.hideTransactionAlert = nil }),
                secondaryButton: .default(.init(Localization.commonHide), action: hideTransactionManually)
            )
        )
    }

    private func hideTransactionManually() {
        hidePendingTx(expressTransactionId: pendingTransaction.expressTransactionId)
        router?.dismissPendingTxSheet()
    }

    private func updateHideButtonState(txStatus: PendingExpressTransactionStatus) {
        switch pendingTransaction.transactionStatus {
        case .paused,
             .refunded,
             .unknown,
             .expired,
             .failed where pendingTransaction.type.branch == .onramp,
             .txFailed where pendingTransaction.type.branch == .swap:
            isHideButtonShowed = true
        case .created,
             .awaitingDeposit,
             .awaitingHash,
             .confirming,
             .buying,
             .exchanging,
             .sendingToUser,
             .finished,
             .verificationRequired,
             .failed,
             .txFailed,
             .refunding:
            isHideButtonShowed = false
        }
    }
}

extension PendingExpressTxStatusBottomSheetViewModel {
    enum Constants {
        static let animationDuration: TimeInterval = 0.3
        static var notificationAnimationDelay: TimeInterval {
            animationDuration + 0.05
        }
    }
}
