//
//  AccountsAwareTokenSelectorItemAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

// MARK: - Provider

protocol AccountsAwareTokenSelectorItemAvailabilityProvider {
    func availabilityTypePublisher(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel
    ) -> AnyPublisher<AccountsAwareTokenSelectorItem.AvailabilityType, Never>
}

// MARK: - Implementations

extension AccountsAwareTokenSelectorItemAvailabilityProvider where Self == AccountsAwareTokenSelectorItemBuyAvailabilityProvider {
    static func buy() -> Self { .init() }
}

extension AccountsAwareTokenSelectorItemAvailabilityProvider where Self == AccountsAwareTokenSelectorItemSellAvailabilityProvider {
    static func sell() -> Self { .init() }
}

extension AccountsAwareTokenSelectorItemAvailabilityProvider where Self == AccountsAwareTokenSelectorItemSwapAvailabilityProvider {
    static func swap() -> Self { .init() }
}

// MARK: - Constant available

struct AvailableAccountsAwareTokenSelectorItemAvailabilityProvider: AccountsAwareTokenSelectorItemAvailabilityProvider {
    func availabilityTypePublisher(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> AnyPublisher<AccountsAwareTokenSelectorItem.AvailabilityType, Never> {
        .just(output: .available)
    }
}
