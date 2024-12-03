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
}

// MARK: - TokenAvailabilitySorter

extension SwapSourceTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [WalletModel]) -> (availableModels: [WalletModel], unavailableModels: [WalletModel]) {
        walletModels.reduce(
            into: (availableModels: [WalletModel](), unavailableModels: [WalletModel]())
        ) { result, walletModel in

            if expressAvailabilityProvider.canSwap(tokenItem: walletModel.tokenItem), !walletModel.isCustom, !walletModel.state.isBlockchainUnreachable {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }
    }
}
