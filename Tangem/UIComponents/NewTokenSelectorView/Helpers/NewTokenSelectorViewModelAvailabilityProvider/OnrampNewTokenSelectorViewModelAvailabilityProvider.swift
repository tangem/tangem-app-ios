//
//  OnrampNewTokenSelectorViewModelAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class OnrampNewTokenSelectorViewModelAvailabilityProvider: NewTokenSelectorViewModelAvailabilityProvider {
    let userWalletConfig: any UserWalletConfig

    init(userWalletConfig: any UserWalletConfig) {
        self.userWalletConfig = userWalletConfig
    }

    func isAvailable(item: NewTokenSelectorItem) -> NewTokenSelectorItemViewModel.DisabledReason? {
        let availabilityProvider = TokenActionAvailabilityProvider(userWalletConfig: userWalletConfig, walletModel: item.walletModel)

        return switch availabilityProvider.buyAvailablity {
        case .available: .none
        default: .unavailableForOnramp
        }
    }
}
