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

    let timeString: String
    let sourceTokenIconInfo: TokenIconInfo
    let destinationTokenIconInfo: TokenIconInfo
    let sourceAmountText: String
    let destinationAmountText: String

    @Published var sourceFiatAmountTextState: LoadableTextView.State = .loading
    @Published var destinationFiatAmountTextState: LoadableTextView.State = .loading
    @Published var statusesList: [PendingExpressTxStatusBottomSheetView.StatusRowData] = []
    @Published var currentStatusIndex = 2
    @Published var showGoToProviderHeader = true

    // Navigation   
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil

    private let pendingTransaction: PendingExpressTransaction
    private let pendingTransactionsManager: PendingExpressTransactionsManager

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()

    private var subscription: AnyCancellable?

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
        setupStatusList(for: pendingTransaction)
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
                let (list, currentIndex) = viewModel.convertToStatusRowDataList(for: pendingTx)
                viewModel.statusesList = list
                viewModel.currentStatusIndex = currentIndex
            }
    }

    private var persistentStateList: [PendingExpressTxStatusBottomSheetView.StatusRowData]?

    private func setupStatusList(for pendingTransaction: PendingExpressTransaction) {
        let (list, currentIndex) = convertToStatusRowDataList(for: pendingTransaction)
        statusesList = list
        currentStatusIndex = currentIndex
    }

    private func convertToStatusRowDataList(for pendingTransaction: PendingExpressTransaction) -> (list: [PendingExpressTxStatusBottomSheetView.StatusRowData], currentIndex: Int) {
        let statuses = pendingTransaction.statuses
        let currentStatusIndex = statuses.firstIndex(of: pendingTransaction.currentStatus) ?? 0
        return (statuses.indexed().map { index, status in
            convertToStatusRowData(index: index, status: status, currentStatusIndex: currentStatusIndex, currentStatus: pendingTransaction.currentStatus, lastStatusIndex: statuses.count - 1)
        }, currentStatusIndex)
    }

    private func convertToStatusRowData(
        index: Int,
        status: PendingExpressTransactionStatus,
        currentStatusIndex: Int,
        currentStatus: PendingExpressTransactionStatus,
        lastStatusIndex: Int
    ) -> PendingExpressTxStatusBottomSheetView.StatusRowData {
        let isCurrentStatus = index == currentStatusIndex
        let isPendingStatus = index > currentStatusIndex
        let isFinished = !currentStatus.isTransactionInProgress
        if isFinished {
            let state: PendingExpressTxStatusBottomSheetView.StatusRowData.State = status == .failed ? .cross(passed: true) : .checkmark
            return .init(
                title: status.passedStatusTitle,
                state: state
            )
        }
        let title: String = isCurrentStatus ? status.activeStatusTitle : isPendingStatus ? status.pendingStatusTitle : status.passedStatusTitle

        var state: PendingExpressTxStatusBottomSheetView.StatusRowData.State =
            isCurrentStatus ? .loader : isPendingStatus ? .empty : .checkmark
        switch status {
        case .failed:
            state = .cross(passed: false)
        case .refunded:
            state = isFinished ? .checkmark : .empty
        case .verificationRequired:
            state = .exclamationMark
        case .awaitingDeposit, .confirming, .exchanging, .sendingToUser, .done:
            break
        }

        return .init(
            title: title,
            state: state
        )
    }
}
