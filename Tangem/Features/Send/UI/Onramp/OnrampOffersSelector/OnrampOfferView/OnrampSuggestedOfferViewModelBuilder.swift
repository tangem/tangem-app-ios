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
        if case .great = provider.globalAttractiveType {
            return .great
        }

        // We're always show only `.great` on the suggested offer view
        if provider.globalAttractiveType == .best {
            return .great
        }

        if provider.processingTimeType == .fastest {
            return .fastest
        }

        return .text(Localization.onrampTitleYouGet)
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
            isAvailable: provider.isSuccessfullyLoaded,
            buyButtonAction: buyAction
        )
    }
}
