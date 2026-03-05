//
//  EarnWalletModelFinder.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

enum EarnWalletModelFinder {
    /// Finds a wallet model for the given token item in the account.
    /// Uses tokens from `userTokensManager` (id + networkId + contractAddress match), then resolves by `WalletModelId`.
    /// - Parameter preferNonCustom: If true, returns a non-custom wallet when multiple matches exist.
    static func findWalletModel(
        for tokenItem: TokenItem,
        in account: any CryptoAccountModel,
        preferNonCustom: Bool = true
    ) -> (any WalletModel)? {
        let walletModelsById = Dictionary(
            uniqueKeysWithValues: account.walletModelsManager.walletModels.map { ($0.id, $0) }
        )

        let matchingTokens = account.userTokensManager.userTokens.filter {
            $0.id == tokenItem.id &&
                $0.blockchain.networkId == tokenItem.blockchain.networkId &&
                $0.contractAddress == tokenItem.contractAddress
        }

        let matchingWalletModels = matchingTokens.compactMap { tokenItem -> (any WalletModel)? in
            let walletModelId = WalletModelId(tokenItem: tokenItem)
            return walletModelsById[walletModelId]
        }

        return preferNonCustom
            ? (matchingWalletModels.first(where: { !$0.isCustom }) ?? matchingWalletModels.first)
            : matchingWalletModels.first
    }
}
