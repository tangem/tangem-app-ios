//
//  OnrampSuggestedOfferViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemLocalization

struct OnrampSuggestedOfferViewModelBuilder {
    let tokenItem: TokenItem

    private let formatter: BalanceFormatter = .init()
    private let processingTimeFormatter: OnrampProviderProcessingTimeFormatter = .init()

    func mapToOnrampOfferViewModelTitle(provider: OnrampProvider) -> OnrampOfferViewModel.Title {
        let title: OnrampOfferViewModel.Title = switch (provider.globalAttractiveType, provider.processingTimeType) {
        // We're always show only `.great` on the suggested offer view
        case (.great, _), (_, .fastest): .great
        case (.best, _): .bestRate
        default: .text(Localization.onrampTitleYouGet)
        }

        return title
    }

    func mapToOnrampOfferViewModel(provider: OnrampProvider, buyAction: @escaping () -> Void) -> OnrampOfferViewModel {
        let title: OnrampOfferViewModel.Title = mapToOnrampOfferViewModelTitle(provider: provider)

        let amount: OnrampOfferViewModel.Amount = {
            let formattedAmount = formatter.formatCryptoBalance(
                provider.quote?.expectedAmount,
                currencyCode: tokenItem.currencySymbol
            )

            return .init(formatted: formattedAmount, badge: .none)
        }()

        let timeFormatted = processingTimeFormatter.format(provider.paymentMethod.type.processingTime)
        let offerProvider: OnrampOfferViewModel.Provider = .init(
            name: provider.provider.name,
            paymentType: provider.paymentMethod,
            timeFormatted: timeFormatted
        )

        return OnrampOfferViewModel(
            title: title,
            amount: amount,
            provider: offerProvider,
            buyButtonAction: buyAction
        )
    }
}
