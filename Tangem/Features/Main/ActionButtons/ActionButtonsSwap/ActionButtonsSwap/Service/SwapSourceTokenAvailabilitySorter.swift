//
//  SwapSourceTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct SwapSourceTokenAvailabilitySorter {
    // MARK: - Dependencies

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider
    private let userWalletModelConfig: UserWalletConfig

    init(userWalletModelConfig: UserWalletConfig) {
        self.userWalletModelConfig = userWalletModelConfig
    }
}

// MARK: - TokenAvailabilitySorter

extension SwapSourceTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [any WalletModel]) -> (availableModels: [any WalletModel], unavailableModels: [any WalletModel]) {
        walletModels.reduce(
            into: (availableModels: [any WalletModel](), unavailableModels: [any WalletModel]())
        ) { result, walletModel in
            let availabilityProvider = TokenActionAvailabilityProvider(userWalletConfig: userWalletModelConfig, walletModel: walletModel)

            if availabilityProvider.isSwapAvailable {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }
    }
}
