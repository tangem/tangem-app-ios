//
//  CommonSellTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct CommonSellTokenAvailabilitySorter {
    // MARK: - Dependencies

    @Injected(\.sellService) private var sellService: SellService
}

// MARK: - TokenAvailabilitySorter

extension CommonSellTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [any WalletModel]) async -> (availableModels: [any WalletModel], unavailableModels: [any WalletModel]) {
        walletModels.reduce(
            into: (availableModels: [any WalletModel](), unavailableModels: [any WalletModel]())
        ) { result, walletModel in
            guard
                sellService.canSell(
                    walletModel.tokenItem.currencySymbol,
                    amountType: walletModel.tokenItem.amountType,
                    blockchain: walletModel.tokenItem.blockchain
                ),
                !walletModel.state.isBlockchainUnreachable,
                walletModel.balanceState == .positive
            else {
                result.unavailableModels.append(walletModel)
                return
            }

            result.availableModels.append(walletModel)
        }
    }
}
