//
//  SwapDestinationTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct SwapDestinationTokenAvailabilitySorter {
    // MARK: - Private property

    private let sourceTokenWalletModel: any WalletModel

    init(
        sourceTokenWalletModel: any WalletModel,
        userWalletModelConfig: UserWalletConfig
    ) {
        self.sourceTokenWalletModel = sourceTokenWalletModel
    }
}

// MARK: - TokenAvailabilitySorter

extension SwapDestinationTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [any WalletModel]) async -> (availableModels: [any WalletModel], unavailableModels: [any WalletModel]) {
        // All tokens are available for swap destination - actual pair check happens on the exchange screen
        // Filter only custom tokens and source token itself
        let result = walletModels.filter { $0.id != sourceTokenWalletModel.id }.reduce(
            into: (availableModels: [any WalletModel](), unavailableModels: [any WalletModel]())
        ) { result, walletModel in
            if walletModel.isCustom {
                result.unavailableModels.append(walletModel)
            } else {
                result.availableModels.append(walletModel)
            }
        }

        return result
    }
}
