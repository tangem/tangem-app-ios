//
//  PendingExpressTxStatusBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class PendingExpressTxStatusBottomSheetViewModel: ObservableObject, Identifiable {
    var providerName: String {
        pendingTransaction.transactionRecord.provider.name
    }

    var providerIconURL: URL? {
        pendingTransaction.transactionRecord.provider.iconURL
    }

    var providerType: String {
        pendingTransaction.transactionRecord.provider.type.rawValue.capitalized
    }

    var animationDuration: TimeInterval {
        Constants.animationDuration
    }

    let timeString: String
    let sourceTokenIconInfo: TokenIconInfo
    let destinationTokenIconInfo: TokenIconInfo
    let sourceAmountText: String
    let destinationAmountText: String

    @Published var sourceFiatAmountTextState: LoadableTextView.State = .loading
    @Published var destinationFiatAmountTextState: LoadableTextView.State = .loading
    @Published var statusesList: [PendingExpressTransactionStatusRow.StatusRowData] = []
    @Published var currentStatusIndex = 2
    @Published var showGoToProviderHeader = true
    @Published var notificationViewInput: NotificationViewInput? = nil

    // Navigation
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil

    private let pendingTransaction: PendingExpressTransaction
    private let pendingTransactionsManager: PendingExpressTransactionsManager

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()

    private var subscription: AnyCancellable?
    private var notificationUpdateWorkItem: DispatchWorkItem?

    init(
        pendingTransaction: PendingExpressTransaction,
        pendingTransactionsManager: PendingExpressTransactionsManager
    ) {
        self.pendingTransaction = pendingTransaction
        self.pendingTransactionsManager = pendingTransactionsManager

        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        timeString = dateFormatter.string(from: pendingTransaction.transactionRecord.date)

        let sourceTokenTxInfo = pendingTransaction.transactionRecord.sourceTokenTxInfo
        let sourceTokenItem = sourceTokenTxInfo.tokenItem
        let destinationTokenTxInfo = pendingTransaction.transactionRecord.destinationTokenTxInfo
        let destinationTokenItem = destinationTokenTxInfo.tokenItem

        let iconInfoBuilder = TokenIconInfoBuilder()
        sourceTokenIconInfo = iconInfoBuilder.build(from: sourceTokenItem, isCustom: sourceTokenTxInfo.isCustom)
        destinationTokenIconInfo = iconInfoBuilder.build(from: destinationTokenItem, isCustom: destinationTokenTxInfo.isCustom)

        sourceAmountText = balanceFormatter.formatCryptoBalance(sourceTokenTxInfo.amount, currencyCode: sourceTokenItem.currencySymbol)
        destinationAmountText = balanceFormatter.formatCryptoBalance(destinationTokenTxInfo.amount, currencyCode: destinationTokenItem.currencySymbol)

        loadEmptyFiatRates()
        updateUI(for: pendingTransaction, delay: 0)
        bind()
    }

    func openProvider() {
        guard
            let urlString = pendingTransaction.transactionRecord.externalTxURL,
            let url = URL(string: urlString)
        else {
            return
        }

        modalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: providerName,
            withCloseButton: true
        )
    }

    private func loadEmptyFiatRates() {
        loadRatesIfNeeded(stateKeyPath: \.sourceFiatAmountTextState, for: pendingTransaction.transactionRecord.sourceTokenTxInfo, on: self)
        loadRatesIfNeeded(stateKeyPath: \.destinationFiatAmountTextState, for: pendingTransaction.transactionRecord.destinationTokenTxInfo, on: self)
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

        if let fiat = balanceConverter.convertToFiat(value: tokenTxInfo.amount, from: currencyId) {
            root[keyPath: stateKeyPath] = .loaded(text: balanceFormatter.formatFiatBalance(fiat))
            return
        }

        Task { [weak root] in
            guard let root = root else { return }

            let fiatAmount = try await root.balanceConverter.convertToFiat(value: tokenTxInfo.amount, from: currencyId)
            let formattedFiat = root.balanceFormatter.formatFiatBalance(fiatAmount)
            await runOnMain {
                root[keyPath: stateKeyPath] = .loaded(text: formattedFiat)
            }
        }
    }

    private func bind() {
        subscription = pendingTransactionsManager.pendingTransactionsPublisher
            .dropFirst()
            .withWeakCaptureOf(self)
            .map { viewModel, pendingTransactions in
                guard let first = pendingTransactions.first(where: { tx in
                    tx.transactionRecord.expressTransactionId == viewModel.pendingTransaction.transactionRecord.expressTransactionId
                }) else {
                    return (viewModel, nil)
                }

                return (viewModel, first)
            }
            .receive(on: DispatchQueue.main)
            .sink { (viewModel: PendingExpressTxStatusBottomSheetViewModel, pendingTx: PendingExpressTransaction?) in
                guard let pendingTx else {
                    viewModel.subscription = nil
                    return
                }

                viewModel.updateUI(for: pendingTx, delay: Constants.notificationAnimationDelay)
            }
    }

    private func updateUI(for pendingTransaction: PendingExpressTransaction, delay: TimeInterval) {
        let converter = PendingExpressTransactionsConverter()
        let (list, currentIndex) = converter.convertToStatusRowDataList(for: pendingTransaction)
        updateUI(statusesList: list, currentIndex: currentIndex, currentStatus: pendingTransaction.currentStatus, delay: delay)
    }

    private func updateUI(statusesList: [PendingExpressTransactionStatusRow.StatusRowData], currentIndex: Int, currentStatus: PendingExpressTransactionStatus, delay: TimeInterval) {
        self.statusesList = statusesList
        currentStatusIndex = currentIndex

        let notificationFactory = NotificationsFactory()
        let event: ExpressNotificationEvent?
        switch currentStatus {
        case .failed:
            event = .cexOperationFailed
        case .verificationRequired:
            event = .verificationRequired
        default:
            event = nil
        }

        guard let event else {
            showGoToProviderHeader = true
            scheduleNotificationUpdate(nil, delay: delay)
            return
        }

        showGoToProviderHeader = false
        scheduleNotificationUpdate(notificationFactory.buildNotificationInput(
            for: event,
            buttonAction: weakify(self, forFunction: PendingExpressTxStatusBottomSheetViewModel.didTapNotification(with:action:))
        ), delay: delay)
    }

    private func scheduleNotificationUpdate(_ newInput: NotificationViewInput?, delay: TimeInterval) {
        notificationUpdateWorkItem?.cancel()
        notificationUpdateWorkItem = nil

        notificationUpdateWorkItem = DispatchWorkItem(block: { [weak self] in
            self?.notificationViewInput = newInput
        })

        // We need to delay notification appearance/disappearance animations
        // to prevent glitches while updating other views (labels, icons, etc.)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: notificationUpdateWorkItem!)
    }
}

extension PendingExpressTxStatusBottomSheetViewModel {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        openProvider()
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
