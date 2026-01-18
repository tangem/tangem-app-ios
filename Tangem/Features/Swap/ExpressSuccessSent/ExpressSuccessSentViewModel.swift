//
//  ExpressSuccessSentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import SwiftUI
import TangemExpress

final class ExpressSuccessSentViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var sourceData: AmountSummaryViewData?
    @Published var destinationData: AmountSummaryViewData?
    @Published var provider: ProviderRowViewModel?
    @Published var expressFee: ExpressFeeRowData?

    var isStatusButtonVisible: Bool {
        data.expressTransactionData.externalTxUrl != nil
    }

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short

        return formatter.string(from: data.date)
    }

    var exploreURL: URL? {
        data.result.url
    }

    var shouldShowShareExploreButtons: Bool {
        !data.source.tokenItem.blockchain.isTransactionAsync
    }

    // MARK: - Dependencies

    private let data: SentExpressTransactionData
    private let appearance: ExpressSuccessSentAppearance
    private let initialTokenItem: TokenItem
    private let balanceConverter: BalanceConverter
    private let balanceFormatter: BalanceFormatter
    private let providerFormatter: ExpressProviderFormatter
    private let feeFormatter: FeeFormatter
    private weak var coordinator: ExpressSuccessSentRoutable?

    init(
        data: SentExpressTransactionData,
        appearance: ExpressSuccessSentAppearance,
        initialTokenItem: TokenItem,
        balanceConverter: BalanceConverter,
        balanceFormatter: BalanceFormatter,
        providerFormatter: ExpressProviderFormatter,
        feeFormatter: FeeFormatter,
        coordinator: ExpressSuccessSentRoutable
    ) {
        self.data = data
        self.appearance = appearance
        self.initialTokenItem = initialTokenItem
        self.balanceConverter = balanceConverter
        self.balanceFormatter = balanceFormatter
        self.providerFormatter = providerFormatter
        self.feeFormatter = feeFormatter
        self.coordinator = coordinator

        setupView()
        logSwapInProgressScreenOpened()
    }

    private func logSwapInProgressScreenOpened() {
        var params: [Analytics.ParameterKey: String] = [
            .provider: data.provider.name,
            .commission: data.feeOption.analyticsValue.rawValue,
            .sendToken: data.source.tokenItem.currencySymbol,
            .receiveToken: data.destination.tokenItem.currencySymbol,
            .sendBlockchain: data.source.tokenItem.blockchain.displayName,
            .receiveBlockchain: data.destination.tokenItem.blockchain.displayName,
        ]

        if FeatureProvider.isAvailable(.accounts) {
            if let sourceAccount = data.source.accountModelAnalyticsProvider {
                let builder = PairedAccountAnalyticsBuilder(role: .source)
                params.merge(sourceAccount.analyticsParameters(with: builder)) { $1 }
            }

            if let destAccount = data.destination.accountModelAnalyticsProvider {
                let builder = PairedAccountAnalyticsBuilder(role: .destination)
                params.merge(destAccount.analyticsParameters(with: builder)) { $1 }
            }
        }

        Analytics.log(event: .swapSwapInProgressScreenOpened, params: params)
    }

    func openExplore(exploreURL: URL) {
        Analytics.log(event: .swapButtonExplore, params: [.token: initialTokenItem.currencySymbol])
        coordinator?.openWebView(url: exploreURL)
    }

    func openCEXStatus() {
        guard let externalTxUrl = data.expressTransactionData.externalTxUrl.flatMap(URL.init(string:)) else {
            return
        }

        Analytics.log(event: .swapButtonStatus, params: [.token: initialTokenItem.currencySymbol])
        coordinator?.openWebView(url: externalTxUrl)
    }

    func closeView() {
        coordinator?.close()
    }
}

private extension ExpressSuccessSentViewModel {
    func setupView() {
        let fromAmount = data.expressTransactionData.fromAmount
        let toAmount = data.expressTransactionData.toAmount
        let sourceTokenItem = data.source.tokenItem
        let destinationTokenItem = data.destination.tokenItem

        let sourceAmountFormatted = balanceFormatter.formatCryptoBalance(fromAmount, currencyCode: sourceTokenItem.currencySymbol)
        let sourceFiatAmount = balanceConverter.convertToFiat(fromAmount, currencyId: sourceTokenItem.currencyId ?? "")
        let sourceFiatAmountFormatted = balanceFormatter.formatFiatBalance(sourceFiatAmount)

        sourceData = AmountSummaryViewData(
            headerType: appearance.sourceCurrencyHeader,
            amount: sourceAmountFormatted,
            amountFiat: sourceFiatAmountFormatted,
            tokenIconInfo: TokenIconInfoBuilder().build(from: sourceTokenItem, isCustom: false)
        )

        let destinationAmountFormatted = balanceFormatter.formatCryptoBalance(toAmount, currencyCode: destinationTokenItem.currencySymbol)
        let destinationFiatAmount = balanceConverter.convertToFiat(toAmount, currencyId: destinationTokenItem.currencyId ?? "")
        let destinationFiatAmountFormatted = balanceFormatter.formatFiatBalance(destinationFiatAmount)

        destinationData = AmountSummaryViewData(
            headerType: appearance.destinationCurrencyHeader,
            amount: destinationAmountFormatted,
            amountFiat: destinationFiatAmountFormatted,
            tokenIconInfo: TokenIconInfoBuilder().build(from: destinationTokenItem, isCustom: false)
        )

        let subtitle = providerFormatter.mapToRateSubtitle(
            fromAmount: fromAmount,
            toAmount: toAmount,
            senderCurrencyCode: sourceTokenItem.currencySymbol,
            destinationCurrencyCode: destinationTokenItem.currencySymbol,
            option: .exchangeRate
        )

        provider = ProviderRowViewModel(
            provider: providerFormatter.mapToProvider(provider: data.provider),
            titleFormat: .name,
            isDisabled: false,
            badge: .none,
            subtitles: [subtitle],
            detailsType: .none
        )

        if !data.source.isExemptFee {
            let feeFormatted = feeFormatter.format(fee: data.fee, tokenItem: data.source.feeTokenItem)
            expressFee = ExpressFeeRowData(title: Localization.commonNetworkFeeTitle, subtitle: .loaded(text: feeFormatted))
        }
    }
}
