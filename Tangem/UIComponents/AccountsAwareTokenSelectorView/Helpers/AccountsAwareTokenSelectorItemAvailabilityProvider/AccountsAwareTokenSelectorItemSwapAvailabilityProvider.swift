//
//  AccountsAwareTokenSelectorItemSwapAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class AccountsAwareTokenSelectorItemSwapAvailabilityProvider {
    private var directionSubscription: AnyCancellable?

    func setup(directionPublisher: some Publisher<SwapDirection?, Never>) {
        // No longer need to fetch pairs - all tokens are available for swap
        // Actual pair check happens on the exchange screen
    }
}

// MARK: - AccountsAwareTokenSelectorItemAvailabilityProvider

extension AccountsAwareTokenSelectorItemSwapAvailabilityProvider: AccountsAwareTokenSelectorItemAvailabilityProvider {
    func availabilityTypePublisher(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> AnyPublisher<AccountsAwareTokenSelectorItem.AvailabilityType, Never> {
        // All tokens are available for swap - actual pair check happens on the exchange screen
        .just(output: .available)
    }
}

// MARK: - SwapDirection

extension AccountsAwareTokenSelectorItemSwapAvailabilityProvider {
    enum SwapDirection {
        case fromSource(TokenItem)
        case toDestination(TokenItem)
    }
}
