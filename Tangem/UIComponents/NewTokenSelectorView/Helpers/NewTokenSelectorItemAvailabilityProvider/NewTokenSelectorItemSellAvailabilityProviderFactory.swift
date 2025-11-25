//
//  NewTokenSelectorItemSellAvailabilityProviderFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

struct NewTokenSelectorItemSellAvailabilityProviderFactory: NewTokenSelectorItemAvailabilityProviderFactory {
    func makeAvailabilityProvider(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> any NewTokenSelectorItemAvailabilityProvider {
        let availabilityTypePublisher = walletModel.actionsUpdatePublisher
            .map { availabilityType(userWalletInfo: userWalletInfo, walletModel: walletModel) }
            .eraseToAnyPublisher()

        return NewTokenSelectorItemSellAvailabilityProvider(
            availabilityTypePublisher: availabilityTypePublisher
        )
    }

    private func availabilityType(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> NewTokenSelectorItem.AvailabilityType {
        let availabilityProvider = TokenActionAvailabilityProvider(
            userWalletConfig: userWalletInfo.config,
            walletModel: walletModel
        )

        return switch availabilityProvider.sellAvailability {
        case .available: .available
        default: .unavailable(reason: .unavailableForSell)
        }
    }
}

// MARK: - NewTokenSelectorItemSellAvailabilityProvider

struct NewTokenSelectorItemSellAvailabilityProvider: NewTokenSelectorItemAvailabilityProvider {
    let availabilityTypePublisher: AnyPublisher<NewTokenSelectorItem.AvailabilityType, Never>
}
