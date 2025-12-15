//
//  NewTokenSelectorItemAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol NewTokenSelectorItemAvailabilityProviderFactory {
    func makeAvailabilityProvider(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> NewTokenSelectorItemAvailabilityProvider
}

protocol NewTokenSelectorItemAvailabilityProvider {
    var availabilityTypePublisher: AnyPublisher<NewTokenSelectorItem.AvailabilityType, Never> { get }
}
