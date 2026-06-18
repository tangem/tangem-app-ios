//
//  TokenSelectorItemAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

// MARK: - Provider

protocol TokenSelectorItemAvailabilityProvider {
    func availabilityTypePublisher(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel
    ) -> AnyPublisher<TokenSelectorItem.AvailabilityType, Never>
}

// MARK: - Implementations

extension TokenSelectorItemAvailabilityProvider where Self == TokenSelectorItemBuyAvailabilityProvider {
    static func buy() -> Self { .init() }
}

extension TokenSelectorItemAvailabilityProvider where Self == TokenSelectorItemSellAvailabilityProvider {
    static func sell() -> Self { .init() }
}

extension TokenSelectorItemAvailabilityProvider where Self == TokenSelectorItemSwapAvailabilityProvider {
    static func swap() -> Self { .init() }
}

extension TokenSelectorItemAvailabilityProvider where Self == TokenSelectorItemAlwaysAvailabilityProvider {
    static func always() -> Self { .init() }
}

// MARK: - Constant available

struct AvailableTokenSelectorItemAvailabilityProvider: TokenSelectorItemAvailabilityProvider {
    func availabilityTypePublisher(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> AnyPublisher<TokenSelectorItem.AvailabilityType, Never> {
        .just(output: .available)
    }
}

final class TokenSelectorItemAlwaysAvailabilityProvider {}

extension TokenSelectorItemAlwaysAvailabilityProvider: TokenSelectorItemAvailabilityProvider {
    func availabilityTypePublisher(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel
    ) -> AnyPublisher<TokenSelectorItem.AvailabilityType, Never> {
        Just(TokenSelectorItem.AvailabilityType.available)
            .eraseToAnyPublisher()
    }
}
