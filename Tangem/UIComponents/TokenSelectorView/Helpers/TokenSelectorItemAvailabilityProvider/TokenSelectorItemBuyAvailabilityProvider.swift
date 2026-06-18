//
//  TokenSelectorItemBuyAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

struct TokenSelectorItemBuyAvailabilityProvider: TokenSelectorItemAvailabilityProvider {
    func availabilityTypePublisher(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> AnyPublisher<TokenSelectorItem.AvailabilityType, Never> {
        let availabilityTypePublisher = walletModel.actionsUpdatePublisher
            .map { availabilityType(userWalletInfo: userWalletInfo, walletModel: walletModel) }
            .eraseToAnyPublisher()

        return availabilityTypePublisher
    }

    private func availabilityType(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> TokenSelectorItem.AvailabilityType {
        let availabilityProvider = TokenActionAvailabilityProvider(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        )

        return switch availabilityProvider.buyAvailablity {
        // A card-linked wallet keeps its tokens selectable so the tap surfaces the backup-support alert
        // downstream (`ActionButtonsBuyViewModel.didSelect`), instead of greying them as "unavailable to purchase".
        case .available, .incompleteBackup: .available
        default: .unavailable(reason: .unavailableForOnramp)
        }
    }
}
