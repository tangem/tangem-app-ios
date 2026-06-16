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

    func mapToRecentOnrampOfferViewModelTitle(provider: OnrampProvider) -> OnrampOfferViewModel.Title {
        switch (provider.globalAttractiveType, provider.processingTimeType) {
        case (.best, _): return .great
        case (.great, _): return .great
        case (_, .fastest): return .fastest
        default: return .text(Localization.onrampTitleYouGet)
        }
    }

    func mapToRecommendedOnrampOfferViewModelTitle(
        suggestedOfferType: OnrampSummaryInteractorSuggestedOfferItem
    ) -> OnrampOfferViewModel.Title {
        switch suggestedOfferType {
        case .great: .great
        case .fastest: .fastest
        case .nativeApplePay(let provider): mapToNativeApplePayTitle(provider: provider)
        case .recent, .plain: .text(Localization.onrampTitleYouGet)
        }
    }

    private func mapToNativeApplePayTitle(provider: OnrampProvider) -> OnrampOfferViewModel.Title {
        switch provider.globalAttractiveType {
        case .best, .great: .great
        case .loss, .none: .fastest
        }
    }

    func mapToOnrampOfferViewModel(
        title: OnrampOfferViewModel.Title,
        provider: OnrampProvider,
        buyAction: OnrampOfferViewModel.BuyAction,
        infoAction: (() -> Void)? = nil,
        legalNotice: OnrampOfferViewModel.LegalNotice? = nil
    ) -> OnrampOfferViewModel {
        let formattedAmount = formatter.formatCryptoBalance(
            provider.quote?.expectedAmount,
            currencyCode: tokenItem.currencySymbol
        )

        let amount = OnrampOfferViewModel.Amount(
            formatted: formattedAmount,
            badge: .none,
            infoAction: infoAction
        )

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
            buyAction: buyAction,
            legalNotice: legalNotice
        )
    }
}
