//
//  SwapSourceTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct SwapSourceTokenAvailabilitySorter {
    // MARK: - Dependencies

    private let userWalletModelConfig: UserWalletConfig

    init(userWalletModelConfig: UserWalletConfig) {
        self.userWalletModelConfig = userWalletModelConfig
    }
}

// MARK: - TokenAvailabilitySorter

extension SwapSourceTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [any WalletModel]) -> (availableModels: [any WalletModel], unavailableModels: [any WalletModel]) {
        // All tokens are available for swap - actual pair check happens on the exchange screen
        // Filter only custom tokens as they cannot be swapped
        let (available, unavailable) = walletModels.reduce(
            into: (availableModels: [any WalletModel](), unavailableModels: [any WalletModel]())
        ) { result, walletModel in
            if walletModel.isCustom {
                result.unavailableModels.append(walletModel)
            } else {
                result.availableModels.append(walletModel)
            }
        }

        return (available, unavailable)
    }
}
