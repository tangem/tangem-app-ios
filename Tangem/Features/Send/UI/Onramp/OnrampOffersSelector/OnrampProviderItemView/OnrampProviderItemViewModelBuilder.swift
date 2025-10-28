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
        let provider = providerItem.maxPriorityProvider()
        let allProviders = providerItem.selectableProviders()

        let amountType: OnrampProviderItemViewModel.AmountType = {
            switch provider?.state {
            case .restriction(.tooSmallAmount(_, let minAmountFormatted)):
                return .availableFrom(amount: minAmountFormatted)
            case .restriction(.tooBigAmount(_, let maxAmountFormatted)):
                return .availableUpTo(amount: maxAmountFormatted)
            case .loaded(let quote):
                let formattedAmount = formatter.formatCryptoBalance(
                    quote.expectedAmount,
                    currencyCode: tokenItem.currencySymbol
                )

                let badge = amountBadgeBuilder.mapToOnrampAmountBadge(provider: provider)
                return .available(.init(formatted: formattedAmount, badge: badge))
            default:
                return .available(.init(formatted: BalanceFormatter.defaultEmptyBalanceString, badge: .none))
            }
        }()

        let providersInfo: OnrampProviderItemViewModel.ProvidersInfo? = {
            guard providerItem.hasSuccessfullyLoadedProviders() else {
                return nil
            }

            return .init(
                providersFormatted: Localization.onrampProvidersCount(allProviders.count),
                timeFormatted: processingTimeFormatter.format(providerItem.paymentMethod.type.processingTime)
            )
        }()

        let paymentMethod = providerItem.paymentMethod
        return OnrampProviderItemViewModel(
            paymentMethod: .init(id: paymentMethod.id, name: paymentMethod.name, iconURL: paymentMethod.image),
            amountType: amountType,
            providersInfo: providersInfo,
            action: tapAction
        )
    }
}
