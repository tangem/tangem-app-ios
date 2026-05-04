//
//  MainQRScanTokenSelectorAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

struct MainQRScanTokenSelectorAvailabilityProvider: TokenSelectorItemAvailabilityProvider {
    let filter: MainQRScanTokenSelectorAvailabilityFilter

    func availabilityTypePublisher(
        userWalletInfo _: UserWalletInfo,
        walletModel: any WalletModel
    ) -> AnyPublisher<TokenSelectorItem.AvailabilityType, Never> {
        Just(availabilityType(for: walletModel))
            .eraseToAnyPublisher()
    }

    private func availabilityType(for walletModel: any WalletModel) -> TokenSelectorItem.AvailabilityType {
        let tokenItem = walletModel.tokenItem

        let isAvailable: Bool
        switch filter {
        case .tokenItems(let compatibleTokenItems):
            isAvailable = compatibleTokenItems.contains(tokenItem)
        case .blockchains(let compatibleBlockchains):
            isAvailable = compatibleBlockchains.contains(tokenItem.blockchain)
        }

        if isAvailable {
            return .available
        }

        return .unavailable(reason: .unavailableForSend)
    }
}
