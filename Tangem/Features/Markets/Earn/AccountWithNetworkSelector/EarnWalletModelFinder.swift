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
        let matchingTokens = account.userTokensManager.userTokens.filter {
            $0.id == tokenItem.id &&
                $0.blockchain.networkId == tokenItem.blockchain.networkId &&
                $0.contractAddress == tokenItem.contractAddress
        }
        let matchingWalletModels = matchingTokens.compactMap {
            walletModel(byTokenItem: $0, in: account)
        }
        return preferNonCustom
            ? (matchingWalletModels.first(where: { !$0.isCustom }) ?? matchingWalletModels.first)
            : matchingWalletModels.first
    }

    private static func walletModel(
        byTokenItem tokenItem: TokenItem,
        in account: any CryptoAccountModel
    ) -> (any WalletModel)? {
        let walletModelId = WalletModelId(tokenItem: tokenItem)
        return account.walletModelsManager.walletModels.first(where: { $0.id == walletModelId })
    }
}
