//
//  MarketsTokenNetworkChecker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Methods will be reused when adapting "Hot Tokens" to account-selection.
enum MarketsTokenNetworkChecker {
    /// Checks if token is added on networks for this account
    static func isTokenAddedOnNetworks(
        account: any CryptoAccountModel,
        coinId: String,
        availableNetworks: [NetworkModel],
        supportedBlockchains: Set<Blockchain>
    ) -> Bool {
        let networksToCheck = networksToCheck(for: account, availableNetworks: availableNetworks, supportedBlockchains: supportedBlockchains)

        guard networksToCheck.isNotEmpty else {
            return true
        }

        let addedNetworks = addedNetworkIds(for: account, coinId: coinId)
        let missingNetworks = networksToCheck.subtracting(addedNetworks)

        return missingNetworks.isEmpty
    }

    /// Checks if token is added on networks across ALL accounts in all wallets
    static func isTokenAddedOnNetworksInAllAccounts(
        coinId: String,
        availableNetworks: [NetworkModel],
        userWalletModels: [any UserWalletModel]
    ) -> Bool {
        guard availableNetworks.isNotEmpty else {
            return true
        }

        let multiCurrencyWallets = userWalletModels.filter { $0.config.hasFeature(.multiCurrency) }

        for wallet in multiCurrencyWallets {
            let accounts = wallet.accountModelsManager.cryptoAccountModels

            for account in accounts {
                let isAddedOnAll = isTokenAddedOnNetworks(
                    account: account,
                    coinId: coinId,
                    availableNetworks: availableNetworks,
                    supportedBlockchains: wallet.config.supportedBlockchains
                )

                if !isAddedOnAll {
                    return false
                }
            }
        }

        return true
    }
}

// MARK: - Private

private extension MarketsTokenNetworkChecker {
    static func networksToCheck(
        for account: any CryptoAccountModel,
        availableNetworks: [NetworkModel],
        supportedBlockchains: Set<Blockchain>
    ) -> Set<String> {
        availableNetworks.compactMap { network in
            guard AccountBlockchainManageabilityChecker.canManageNetwork(network.networkId, for: account, in: supportedBlockchains) else {
                return nil
            }

            guard NetworkSupportChecker.isNetworkSupported(network, in: supportedBlockchains) else {
                return nil
            }

            return network.networkId
        }
        .toSet()
    }

    static func addedNetworkIds(
        for account: any CryptoAccountModel,
        coinId: String
    ) -> Set<String> {
        let l2BlockchainIds = Set(SupportedBlockchains.l2Blockchains.map(\.coinId))
        var result = Set<String>()

        for token in account.userTokensManager.userTokens {
            if let networkId = matchingNetworkId(for: token, coinId: coinId, l2BlockchainIds: l2BlockchainIds) {
                result.insert(networkId)
            }
        }

        return result
    }

    static func matchingNetworkId(
        for token: TokenItem,
        coinId: String,
        l2BlockchainIds: Set<String>
    ) -> String? {
        guard let tokenId = token.id else {
            return nil
        }

        if coinId == Blockchain.ethereum(testnet: false).coinId, l2BlockchainIds.contains(tokenId) {
            return token.networkId
        }

        guard tokenId == coinId else {
            return nil
        }

        return token.networkId
    }
}
