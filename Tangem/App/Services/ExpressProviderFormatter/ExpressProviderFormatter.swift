//
//  ExpressProviderFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

struct ExpressProviderFormatter {
    let balanceFormatter: BalanceFormatter

    func mapToRateSubtitle(
        quote: ExpectedQuote,
        senderCurrencyCode: String?,
        destinationCurrencyCode: String?,
        option: RateSubtitleFormattingOption
    ) -> ProviderRowViewModel.Subtitle {
        switch quote.state {
        case .quote(let expressQuote):
            switch option {
            case .rate:
                guard let senderCurrencyCode, let destinationCurrencyCode else {
                    return .text(CommonError.noData.localizedDescription)
                }

                let rate = expressQuote.expectAmount / expressQuote.fromAmount
                let formattedSourceAmount = balanceFormatter.formatCryptoBalance(1, currencyCode: senderCurrencyCode)
                let formattedDestinationAmount = balanceFormatter.formatCryptoBalance(rate, currencyCode: destinationCurrencyCode)

                return .text("\(formattedSourceAmount) ≈ \(formattedDestinationAmount)")
            case .destination:
                guard let destinationCurrencyCode else {
                    return .text(CommonError.noData.localizedDescription)
                }

                let formatted = balanceFormatter.formatCryptoBalance(expressQuote.expectAmount, currencyCode: destinationCurrencyCode)
                return .text(formatted)
            }

        case .error(let string):
            return .text(string)
        case .notAvailable:
            return .text(Localization.expressProviderNotAvailable)
        case .tooSmallAmount(let minAmount):
            guard let senderCurrencyCode else {
                return .text(CommonError.noData.localizedDescription)
            }

            let formatted = balanceFormatter.formatCryptoBalance(minAmount, currencyCode: senderCurrencyCode)
            return .text(Localization.expressProviderMinAmount(formatted))
        }
    }

    func mapToProvider(provider: ExpressProvider) -> ProviderRowViewModel.Provider {
        ProviderRowViewModel.Provider(
            iconURL: provider.url,
            name: provider.name,
            type: provider.type.rawValue.uppercased()
        )
    }
}

extension ExpressProviderFormatter {
    enum RateSubtitleFormattingOption {
        // How many destination's tokens user will get for the 1 token of source
        case rate

        // How many destination's tokens user will get at the end of swap
        case destination
    }
}
