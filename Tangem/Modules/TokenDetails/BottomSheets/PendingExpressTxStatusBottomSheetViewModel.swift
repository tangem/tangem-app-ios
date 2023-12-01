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
        record.provider.name
    }

    var providerIconURL: URL? {
        record.provider.url
    }

    var providerType: String {
        record.provider.type.rawValue.capitalized
    }

    let timeString: String
    let sourceTokenIconInfo: TokenIconInfo
    let destinationTokenIconInfo: TokenIconInfo
    let sourceAmountText: String
    let destinationAmountText: String

    @Published var sourceFiatAmountTextState: LoadableTextView.State
    @Published var destinationFiatAmountTextState: LoadableTextView.State
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil

    private let record: ExpressPendingTransactionRecord

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()

    init(record: ExpressPendingTransactionRecord) {
        self.record = record

        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        timeString = dateFormatter.string(from: record.date)

        let sourceTokenTxInfo = record.sourceTokenTxInfo
        let sourceTokenItem = sourceTokenTxInfo.tokenItem
        let destinationTokenTxInfo = record.destinationTokenTxInfo
        let destinationTokenItem = destinationTokenTxInfo.tokenItem

        let iconInfoBuilder = TokenIconInfoBuilder()
        sourceTokenIconInfo = iconInfoBuilder.build(from: sourceTokenItem, isCustom: sourceTokenTxInfo.isCustom)
        destinationTokenIconInfo = iconInfoBuilder.build(from: destinationTokenItem, isCustom: destinationTokenTxInfo.isCustom)

        sourceAmountText = balanceFormatter.formatCryptoBalance(sourceTokenTxInfo.amount, currencyCode: sourceTokenItem.currencySymbol)
        if let currencyId = sourceTokenItem.currencyId {
            if let sourceFiat = balanceConverter.convertToFiat(value: sourceTokenTxInfo.amount, from: currencyId) {
                sourceFiatAmountTextState = .loaded(text: balanceFormatter.formatFiatBalance(sourceFiat))
            } else {
                sourceFiatAmountTextState = .loading
            }
        } else {
            sourceFiatAmountTextState = .noData
        }

        destinationAmountText = balanceFormatter.formatCryptoBalance(destinationTokenTxInfo.amount, currencyCode: destinationTokenItem.currencySymbol)
        if let currencyId = destinationTokenTxInfo.tokenItem.currencyId {
            if let destinationFiat = balanceConverter.convertToFiat(value: destinationTokenTxInfo.amount, from: currencyId) {
                destinationFiatAmountTextState = .loaded(text: balanceFormatter.formatFiatBalance(destinationFiat))
            } else {
                destinationFiatAmountTextState = .loading
            }
        } else {
            destinationFiatAmountTextState = .noData
        }

        loadEmptyRates()
    }

    func openProvider() {
        guard
            let urlString = record.externalTxURL,
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

    private func loadEmptyRates() {
        loadRatesIfNeeded(stateKeyPath: \.sourceFiatAmountTextState, for: record.sourceTokenTxInfo, on: self)
        loadRatesIfNeeded(stateKeyPath: \.destinationFiatAmountTextState, for: record.destinationTokenTxInfo, on: self)
    }

    private func loadRatesIfNeeded(
        stateKeyPath: ReferenceWritableKeyPath<PendingExpressTxStatusBottomSheetViewModel, LoadableTextView.State>,
        for tokenTxInfo: ExpressPendingTransactionRecord.TokenTxInfo,
        on root: PendingExpressTxStatusBottomSheetViewModel
    ) {
        guard root[keyPath: stateKeyPath] == .loading else {
            return
        }

        guard let currencyId = tokenTxInfo.tokenItem.currencyId else {
            root[keyPath: stateKeyPath] = .noData
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
}
