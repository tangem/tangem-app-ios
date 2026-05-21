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

    func mapToOnrampOfferViewModel(
        provider: OnrampProvider,
        buyAction: OnrampOfferViewModel.BuyAction,
        infoAction: (() -> Void)? = nil
    ) -> OnrampOfferViewModel {
        let isNativeApplePay = buyAction.isNativeApplePay

        let title: OnrampOfferViewModel.Title = {
            if isNativeApplePay {
                return .text(Localization.onrampTitleYouGet)
            }
            switch provider.state {
            case .loaded where provider.globalAttractiveType == .best: return .bestRate
            case .loaded where provider.processingTimeType == .fastest: return .fastest
            case .restriction(.tooSmallAmount): return .text(Localization.onrampProviderMinAmount(""))
            case .restriction(.tooBigAmount): return .text(Localization.onrampProviderMaxAmount(""))
            default: return .text(Localization.onrampTitleYouGet)
            }
        }()

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

            let badge = isNativeApplePay ? nil : amountBadgeBuilder.mapToOnrampAmountBadge(provider: provider)
            return OnrampOfferViewModel.Amount(formatted: formattedAmount, badge: badge, infoAction: infoAction)
        }()

        let timeFormatted = processingTimeFormatter.format(provider.paymentMethod.type.processingTime)
        let offerProvider: OnrampOfferViewModel.Provider = .init(
            name: provider.provider.name,
            paymentType: provider.paymentMethod,
            timeFormatted: timeFormatted
        )

        let legalNotice = isNativeApplePay ? OnrampNativePaymentLegalLinks.legalNotice(for: provider) : nil

        return OnrampOfferViewModel(
            title: title,
            amount: amount,
            provider: offerProvider,
            isAvailable: provider.isSuccessfullyLoaded,
            buyAction: buyAction,
            legalNotice: legalNotice
        )
    }
}
