//
//  OnrampProviderItemViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemLocalization

struct OnrampProviderItemViewModelBuilder {
    let tokenItem: TokenItem

    private let formatter: BalanceFormatter = .init()
    private let amountBadgeBuilder: OnrampAmountBadgeBuilder = .init()
    private let processingTimeFormatter: OnrampProviderProcessingTimeFormatter = .init()

    func mapToOnrampProviderItemViewModel(providerItem: ProviderItem, tapAction: @escaping () -> Void) -> OnrampProviderItemViewModel {
        let paymentMethod = providerItem.paymentMethod
        let providers = providerItem.successfullyLoadedProviders()
        let providersFormatted = Localization.onrampProvidersCount(providers.count)

        let amount: OnrampProviderItemViewModel.Amount = {
            let provider = providers.first
            let formattedAmount = formatter.formatCryptoBalance(
                provider?.quote?.expectedAmount,
                currencyCode: tokenItem.currencySymbol
            )

            let badge = amountBadgeBuilder.mapToOnrampAmountBadge(provider: provider)
            return .init(formatted: formattedAmount, badge: badge)
        }()

        let timeFormatted = processingTimeFormatter.format(providerItem.paymentMethod.type.processingTime)

        return OnrampProviderItemViewModel(
            paymentMethod: .init(id: paymentMethod.id, name: paymentMethod.name, iconURL: paymentMethod.image),
            amount: amount,
            providersFormatted: providersFormatted,
            timeFormatted: timeFormatted,
            action: tapAction
        )
    }
}
