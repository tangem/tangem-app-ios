//
//  StoredCryptoAccountsMerger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
struct StoredCryptoAccountsMerger {
    /// If true, the `tokens` field of accounts from the `oldAccounts` array will be preserved
    /// instead of being overwritten by the `token` field of accounts from the `newAccounts` array.
    /// - Note: Has no effect when merging token items into a single account (using `merge(newTokenItems:to:)` method).
    let preserveTokensWhileMergingAccounts: Bool

    func merge(
        oldAccounts: [StoredCryptoAccount],
        newAccounts: [StoredCryptoAccount]
    ) -> (accounts: [StoredCryptoAccount], isDirty: Bool) {
        var updatedAccounts = oldAccounts
        var isDirty = false

        // Fast lookup dictionary to find existing accounts by their derivation index
        let indicesKeyedByDerivationIndex: [Int: Int] = oldAccounts
            .enumerated()
            .reduce(into: [:]) { partialResult, input in
                let (index, account) = input
                partialResult[account.derivationIndex] = index
            }

        for newAccount in newAccounts {
            if let targetIndex = indicesKeyedByDerivationIndex[newAccount.derivationIndex] {
                let existingAccount = updatedAccounts[targetIndex]

                // Exclude `tokens` field of new account from comparison if we need to preserve existing tokens
                let newAccount = preserveTokensWhileMergingAccounts
                    ? newAccount.withTokens(existingAccount.tokens)
                    : newAccount

                if existingAccount != newAccount {
                    isDirty = true
                }

                updatedAccounts[targetIndex] = newAccount
            } else {
                isDirty = true
                updatedAccounts.append(newAccount)
            }
        }

        return (updatedAccounts, isDirty)
    }

    /// Backport of logic from the `CommonTokenItemsRepository.append(_:)` method.
    func merge(
        newTokenItems: [TokenItem],
        to cryptoAccount: StoredCryptoAccount
    ) -> (account: StoredCryptoAccount, isDirty: Bool) {
        var updatedTokens = cryptoAccount.tokens
        var isDirty = false

        var existingNetworksToUpdate: [BlockchainNetwork] = []
        let knownExistingNetworks = updatedTokens.compactMap(\.blockchainNetwork.knownValue).toSet()

        let newTokenItemsGroupedByNetworks = newTokenItems.grouped(by: \.blockchainNetwork)
        let newNetworks = newTokenItems.uniqueProperties(\.blockchainNetwork)

        // First loop: determine which networks are new and which already exist. New networks will be added entirely, including all tokens.
        for network in newNetworks {
            if knownExistingNetworks.contains(network) {
                // This blockchain network already exists, and it probably needs to be updated with new tokens, in the second loop
                existingNetworksToUpdate.append(network)
            } else if let newTokenItems = newTokenItemsGroupedByNetworks[network] {
                // New blockchain network, just appending all entries from it to the end of the existing list
                updatedTokens.append(contentsOf: newTokenItems.map { $0.toStoredToken() })
                isDirty = true
            }
        }

        // Second loop: update only existing networks with new tokens
        for network in existingNetworksToUpdate {
            guard let newTokenItemsForExistingNetwork = newTokenItemsGroupedByNetworks[network] else {
                continue
            }

            for newTokenItem in newTokenItemsForExistingNetwork {
                // We already have this network, so only tokens are gonna be added
                guard newTokenItem.isToken else {
                    continue
                }

                if let index = updatedTokens.firstIndex(where: { $0.isEqual(to: newTokenItem, in: network) }) {
                    if updatedTokens[index].id == nil, newTokenItem.id != nil {
                        // Entry has been saved without id, just updating this entry
                        updatedTokens[index] = newTokenItem.toStoredToken() // upgrading custom token
                        isDirty = true
                    }
                } else {
                    // Token hasn't been added yet, just appending it to the end of the existing list
                    updatedTokens.append(newTokenItem.toStoredToken())
                    isDirty = true
                }
            }
        }

        let updatedAccount = cryptoAccount.withTokens(updatedTokens)

        return (updatedAccount, isDirty)
    }
}

// MARK: - Convenience extensions

private extension StoredCryptoAccount.Token {
    func isEqual(to tokenItem: TokenItem, in network: BlockchainNetwork) -> Bool {
        return blockchainNetwork.knownValue == network && contractAddress == tokenItem.contractAddress
    }
}
