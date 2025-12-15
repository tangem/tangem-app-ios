//
//  WalletModelsTotalBalanceStateBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WalletModelsTotalBalanceStateBuilder {
    private let walletModelsManager: WalletModelsManager
    private let tokenBalanceTypesCombiner: TokenBalanceTypesCombiner

    init(
        walletModelsManager: WalletModelsManager,
        tokenBalanceTypesCombiner: TokenBalanceTypesCombiner = .init()
    ) {
        self.walletModelsManager = walletModelsManager
        self.tokenBalanceTypesCombiner = tokenBalanceTypesCombiner
    }

    func buildTotalBalanceState() -> TotalBalanceState {
        guard walletModelsManager.isInitialized else {
            // We are still waiting when list of wallet models will be created
            return .loading(cached: .none)
        }

        let balances = walletModelsManager.walletModels.map {
            TokenBalanceTypesCombiner.Balance(item: $0.tokenItem, balance: $0.fiatTotalTokenBalanceProvider.balanceType)
        }

        return tokenBalanceTypesCombiner.mapToTotalBalance(balances: balances)
    }
}
