//
//  OnrampNewTokenSelectorItemAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class OnrampNewTokenSelectorItemAvailabilityProvider: NewTokenSelectorItemAvailabilityProvider {
    func isAvailable(item: NewTokenSelectorItem) -> NewTokenSelectorItemViewModel.DisabledReason? {
        let availabilityProvider = TokenActionAvailabilityProvider(
            userWalletConfig: item.wallet.userWalletInfo.config,
            walletModel: item.walletModel
        )

        return switch availabilityProvider.buyAvailablity {
        case .available: .none
        default: .unavailableForOnramp
        }
    }
}
