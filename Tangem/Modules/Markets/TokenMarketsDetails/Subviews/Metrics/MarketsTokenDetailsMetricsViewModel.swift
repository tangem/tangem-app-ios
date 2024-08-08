//
//  MarketsTokenDetailsMetricsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsMetricsViewModel {
    let records: [MarketsTokenDetailsMetricsView.RecordInfo]

    private let notationFormatter: DefaultAmountNotationFormatter
    private weak var infoRouter: MarketsTokenDetailsBottomSheetRouter?

    init(
        metrics: MarketsTokenDetailsMetrics,
        notationFormatter: DefaultAmountNotationFormatter,
        cryptoCurrencyCode: String,
        infoRouter: MarketsTokenDetailsBottomSheetRouter?
    ) {
        self.notationFormatter = notationFormatter
        self.infoRouter = infoRouter

        let amountNotationFormatter = AmountNotationSuffixFormatter(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)
        let formatter = BalanceFormatter()
        let fiatFormatter = NumberFormatter()
        let options = BalanceFormattingOptions(minFractionDigits: 0, maxFractionDigits: 0, formatEpsilonAsLowestRepresentableValue: false, roundingType: .default(roundingMode: .plain, scale: 0))
        formatter.prepareFiatFormatter(for: AppSettings.shared.selectedCurrencyCode, formatter: fiatFormatter, formattingOptions: options)
        let fiatCurrencySymbol = fiatFormatter.currencySymbol ?? ""
        let emptyValue = BalanceFormatter.defaultEmptyBalanceString

        func formatFiatValue(_ value: Decimal?) -> String {
            guard let value, value > 0 else {
                return emptyValue
            }

            return formatter.formatFiatBalance(value, formattingOptions: options)
        }

        func formatCryptoValue(_ value: Decimal?) -> String {
            formatter.formatCryptoBalance(value, currencyCode: cryptoCurrencyCode)
        }

        var rating = emptyValue
        if let marketRating = metrics.marketRating, marketRating > 0 {
            rating = formatter.formatCryptoBalance(Decimal(marketRating), currencyCode: "", formattingOptions: options)
        }
        records = [
            .init(type: .marketCapitalization, recordData: notationFormatter.format(metrics.marketCap, currencySymbol: fiatCurrencySymbol)),
            .init(type: .marketRating, recordData: rating),
            .init(type: .tradingVolume, recordData: notationFormatter.format(metrics.volume24H, currencySymbol: fiatCurrencySymbol)),
            .init(type: .fullyDilutedValuation, recordData: notationFormatter.format(metrics.fullyDilutedValuation, currencySymbol: fiatCurrencySymbol)),
            .init(type: .circulatingSupply, recordData: notationFormatter.format(metrics.circulatingSupply, currencySymbol: cryptoCurrencyCode)),
            .init(type: .totalSupply, recordData: notationFormatter.format(metrics.totalSupply, currencySymbol: cryptoCurrencyCode)),
        ]
    }

    func showInfoBottomSheet(for type: MarketsTokenDetailsInfoDescriptionProvider) {
        infoRouter?.openInfoBottomSheet(title: type.title, message: type.infoDescription)
    }
}
