//
//  OnrampOfferViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemLocalization

struct OnrampOfferViewModelBuilder {
    let tokenItem: TokenItem

    private let formatter: BalanceFormatter = .init()
    private let percentFormatter: PercentFormatter = .init()
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

            switch provider.globalAttractiveType {
            case .best:
                return .init(formatted: formattedAmount, badge: .best)
            case .loss(let percent):
                let formattedPercent = percentFormatter.format(percent, option: .express)
                return .init(formatted: formattedAmount, badge: .loss(percent: formattedPercent, signType: .negative))
            case .none:
                return .init(formatted: formattedAmount, badge: .none)
            }
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
