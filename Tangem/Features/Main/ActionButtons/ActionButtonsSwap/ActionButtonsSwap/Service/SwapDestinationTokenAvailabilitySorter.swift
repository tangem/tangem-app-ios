//
//  SwapDestinationTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

struct SwapDestinationTokenAvailabilitySorter {
    // MARK: - Dependencies

    @Injected(\.swapRepository)
    private var swapRepository: SwapRepository

    // MARK: - Private property

    private let sourceTokenWalletModel: any WalletModel
    private let userWalletModelConfig: UserWalletConfig

    init(
        sourceTokenWalletModel: any WalletModel,
        userWalletModelConfig: UserWalletConfig
    ) {
        self.sourceTokenWalletModel = sourceTokenWalletModel
        self.userWalletModelConfig = userWalletModelConfig
    }
}

// MARK: - TokenAvailabilitySorter

extension SwapDestinationTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [any WalletModel]) async -> (availableModels: [any WalletModel], unavailableModels: [any WalletModel]) {
        let availablePairs = await swapRepository.getPairs(from: sourceTokenWalletModel.tokenItem.expressCurrency)

        let result = walletModels.filter { $0.id != sourceTokenWalletModel.id }.reduce(
            into: (availableModels: [any WalletModel](), unavailableModels: [any WalletModel]())
        ) { result, walletModel in
            let availabilityProvider = TokenActionAvailabilityProvider(userWalletConfig: userWalletModelConfig, walletModel: walletModel)

            if availablePairs.map(\.destination).contains(walletModel.tokenItem.expressCurrency.asCurrency),
               availabilityProvider.isSwapAvailable {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }

        return result
    }
}
