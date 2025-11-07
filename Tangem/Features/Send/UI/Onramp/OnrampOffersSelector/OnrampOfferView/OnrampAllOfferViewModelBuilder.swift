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
        let title: OnrampOfferViewModel.Title = switch provider.state {
        case .loaded where provider.globalAttractiveType == .best: .bestRate
        case .loaded where provider.processingTimeType == .fastest: .fastest
        case .restriction(.tooSmallAmount): .text(Localization.onrampProviderMinAmount(""))
        case .restriction(.tooBigAmount): .text(Localization.onrampProviderMaxAmount(""))
        default: .text(Localization.onrampTitleYouGet)
        }

        let amount: OnrampOfferViewModel.Amount = {
            let formattedAmount = switch provider.state {
            case .loaded(let quote):
                formatter.formatCryptoBalance(quote.expectedAmount, currencyCode: tokenItem.currencySymbol)
            case .restriction(.tooSmallAmount(_, let minAmountFormatted)):
                minAmountFormatted
            case .restriction(.tooBigAmount(_, let maxAmountFormatted)):
                maxAmountFormatted
            default:
                BalanceFormatter.defaultEmptyBalanceString
            }

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
            isAvailable: provider.isSuccessfullyLoaded,
            buyButtonAction: buyAction
        )
    }
}
