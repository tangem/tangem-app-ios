//
//  OnrampOfferViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemLocalization

struct OnrampAllOfferViewModelBuilder {
    let tokenItem: TokenItem

    private let formatter: BalanceFormatter = .init()
    private let amountBadgeBuilder: OnrampAmountBadgeBuilder = .init()
    private let processingTimeFormatter: OnrampProviderProcessingTimeFormatter = .init()

    func mapToOnrampOfferViewModel(provider: OnrampProvider, buyAction: @escaping () -> Void) -> OnrampOfferViewModel {
        let title: OnrampOfferViewModel.Title = switch (provider.globalAttractiveType, provider.processingTimeType) {
        case (.best, _): .bestRate
        case (_, .fastest): .fastest
        default: .text(Localization.onrampTitleYouGet)
        }

        let amount: OnrampOfferViewModel.Amount = {
            let formattedAmount = formatter.formatCryptoBalance(
                provider.quote?.expectedAmount,
                currencyCode: tokenItem.currencySymbol
            )

            let badge = amountBadgeBuilder.mapToOnrampAmountBadge(provider: provider)
            return .init(formatted: formattedAmount, badge: badge)
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
