//
//  AccountsAwareTokenSelectorItemBuyAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

struct AccountsAwareTokenSelectorItemBuyAvailabilityProvider: AccountsAwareTokenSelectorItemAvailabilityProvider {
    func availabilityTypePublisher(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> AnyPublisher<AccountsAwareTokenSelectorItem.AvailabilityType, Never> {
        let availabilityTypePublisher = walletModel.actionsUpdatePublisher
            .map { availabilityType(userWalletInfo: userWalletInfo, walletModel: walletModel) }
            .eraseToAnyPublisher()

        return availabilityTypePublisher
    }

    private func availabilityType(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> AccountsAwareTokenSelectorItem.AvailabilityType {
        let availabilityProvider = TokenActionAvailabilityProvider(
            userWalletConfig: userWalletInfo.config,
            walletModel: walletModel
        )

        return switch availabilityProvider.buyAvailablity {
        case .available: .available
        default: .unavailable(reason: .unavailableForOnramp)
        }
    }
}
