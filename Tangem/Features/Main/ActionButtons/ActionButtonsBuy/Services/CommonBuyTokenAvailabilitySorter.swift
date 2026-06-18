//
//  CommonBuyTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct CommonBuyTokenAvailabilitySorter {
    let userWalletInfo: UserWalletInfo
}

// MARK: - TokenAvailabilitySorter

extension CommonBuyTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [any WalletModel]) async -> (availableModels: [any WalletModel], unavailableModels: [any WalletModel]) {
        walletModels.reduce(
            into: (availableModels: [any WalletModel](), unavailableModels: [any WalletModel]())
        ) { result, walletModel in
            if tokenAvailableToBuy(walletModel) {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }
    }

    private func tokenAvailableToBuy(_ walletModel: any WalletModel) -> Bool {
        let availabilityProvider = TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel)
        return availabilityProvider.isBuyAvailable
    }
}
