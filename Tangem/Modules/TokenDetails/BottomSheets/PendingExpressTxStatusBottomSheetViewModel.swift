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
            .withWeakCaptureOf(self)
            .map { viewModel, pendingTransactions in
                guard let first = pendingTransactions.first(where: { tx in
                    tx.transactionRecord.expressTransactionId == viewModel.pendingTransaction.transactionRecord.expressTransactionId
                }) else {
                    return viewModel.pendingTransaction
                }

                return first
            }
            .sink()
    }
}
