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
    private let percentFormatter: PercentFormatter = .init()
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

            switch provider?.globalAttractiveType {
            case .best:
                return .init(formatted: formattedAmount, badge: .best)
            case .loss(let percent):
                let formattedPercent = percentFormatter.format(percent, option: .express)
                return .init(formatted: formattedAmount, badge: .loss(percent: formattedPercent, signType: .negative))
            case .none:
                return .init(formatted: formattedAmount, badge: .none)
            }
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
