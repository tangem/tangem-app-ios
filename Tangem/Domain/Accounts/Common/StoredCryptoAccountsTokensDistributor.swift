//
//  StoredCryptoAccountsTokensDistributor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import enum BlockchainSdk.Blockchain

// [REDACTED_TODO_COMMENT]
enum StoredCryptoAccountsTokensDistributor {
    private typealias Cache = [Blockchain: AccountDerivationPathHelper]

    /// Distributes tokens among existing crypto accounts based on their derivation indexes.
    /// - Parameters:
    ///  - storedCryptoAccounts: The list of existing crypto accounts to redistribute tokens among. This array is modified in place.
    ///  - additionalTokens: An optional list of tokens that should be distributed among the accounts,
    ///  if accounts with these tokens' derivation indexes exist. If such accounts do not exist, these tokens are added to the `Main` account.
    /// - Returns: `true` if any tokens were redistributed (i.e. a `dirty` bit), `false` otherwise.
    static func distributeTokens(
        in storedCryptoAccounts: inout [StoredCryptoAccount],
        additionalTokens: [StoredCryptoAccount.Token] = []
    ) -> Bool {
        // First loop (required) - building the list of existing accounts, keyed by their derivation indexes
        var vacantTokensToDistribute: [Int: [StoredCryptoAccount.Token]] = storedCryptoAccounts
            .reduce(into: [:]) { partialResult, account in
                partialResult[account.derivationIndex] = []
            }

        var isDirty = false
        let hasAdditionalTokens = additionalTokens.isNotEmpty

        // Helpers are cached for efficiency since there is limited and finite number of blockchains
        var cachedHelpers: Cache = [:]

        // Second loop (required) - removing tokens that belong to other existing accounts
        for (index, account) in storedCryptoAccounts.enumerated() {
            var updatedAccountTokens: [StoredCryptoAccount.Token] = []

            for token in account.tokens {
                guard let tokenAccountDerivationIndex = extractAccountDerivationIndex(from: token, using: &cachedHelpers) else {
                    // Unsupported network and/or token, no derivation path and/or account derivation node, etc
                    // Keeping this token in its original account as is
                    updatedAccountTokens.append(token)
                    continue
                }

                if tokenAccountDerivationIndex != account.derivationIndex, vacantTokensToDistribute[tokenAccountDerivationIndex] != nil {
                    // This token belongs to another existing account, and there exists an account with such derivation index,
                    // moving this token to that account
                    vacantTokensToDistribute[tokenAccountDerivationIndex]?.append(token)
                    isDirty = true
                } else {
                    // Keeping this token in its original account as is
                    updatedAccountTokens.append(token)
                }
            }

            storedCryptoAccounts[index] = account.withTokens(updatedAccountTokens)
        }

        guard isDirty || hasAdditionalTokens else {
            return false
        }

        // Third loop (optional) - appending the tokens that were removed in the second loop to their respective accounts
        for (index, account) in storedCryptoAccounts.enumerated() {
            guard let additionalTokens = vacantTokensToDistribute[account.derivationIndex] else {
                continue
            }

            storedCryptoAccounts[index] = account.withTokens(account.tokens + additionalTokens)
        }

        // Distributing additional tokens if any (optional)
        let didAddAdditionalTokens = add(additionalTokens: additionalTokens, to: &storedCryptoAccounts, using: &cachedHelpers)

        return isDirty || didAddAdditionalTokens
    }

    // MARK: - Private implementation

    /// Adds tokens from `additionalTokens` to existing accounts based on their derivation indexes.
    /// If there are no accounts with the respective derivation indexes, these remaining tokens are added to the `Main` account.
    private static func add(
        additionalTokens: [StoredCryptoAccount.Token],
        to storedCryptoAccounts: inout [StoredCryptoAccount],
        using cachedHelpers: inout Cache
    ) -> Bool {
        var isDirty = false

        guard additionalTokens.isNotEmpty else {
            return isDirty
        }

        // These tokens goes to the `Main` account because there are no accounts with their derivation indexes
        var remainingTokens: [StoredCryptoAccount.Token] = []
        // This is an array index, not a derivation index
        var mainAccountIndex: Int?

        // First loop (required) - building the list of existing accounts, keyed by their derivation indexes
        var vacantTokensToDistribute: [Int: [StoredCryptoAccount.Token]] = storedCryptoAccounts
            .reduce(into: [:]) { partialResult, account in
                partialResult[account.derivationIndex] = []
            }

        // Second loop (required) - processing additional tokens
        for token in additionalTokens {
            guard let tokenAccountDerivationIndex = extractAccountDerivationIndex(from: token, using: &cachedHelpers) else {
                // Unsupported network and/or token, no derivation path and/or account derivation node, etc
                // Ignoring this token since there is nothing we can do with it
                continue
            }

            if vacantTokensToDistribute[tokenAccountDerivationIndex] != nil {
                // This token belongs to another existing account, and there exists an account with such derivation index,
                // moving this token to that account
                vacantTokensToDistribute[tokenAccountDerivationIndex]?.append(token)
            } else {
                // Adding this token to the `Main` account since there is no account with such derivation index
                remainingTokens.append(token)
            }

            isDirty = true
        }

        // Third loop (optional) - appending the tokens that were prepared in the second loop to their respective accounts.
        // And in the same time, finding the `Main` account index.
        for (index, account) in storedCryptoAccounts.enumerated() {
            if AccountModelUtils.isMainAccount(account.derivationIndex) {
                mainAccountIndex = index
            }

            guard let additionalTokens = vacantTokensToDistribute[account.derivationIndex] else {
                continue
            }

            storedCryptoAccounts[index] = account.withTokens(account.tokens + additionalTokens)
        }

        guard remainingTokens.isNotEmpty else {
            return isDirty
        }

        guard let mainAccountIndex else {
            let message = "No main account found to add \(remainingTokens.count) remaining tokens to"
            assertionFailure(message)
            AccountsLogger.warning(message)
            return isDirty
        }

        let mainAccountTokens = storedCryptoAccounts[mainAccountIndex].tokens + remainingTokens
        storedCryptoAccounts[mainAccountIndex] = storedCryptoAccounts[mainAccountIndex].withTokens(mainAccountTokens)

        return isDirty
    }

    private static func extractAccountDerivationIndex(
        from token: StoredCryptoAccount.Token,
        using cachedHelpers: inout Cache
    ) -> Int? {
        guard let blockchainNetwork = token.blockchainNetwork.knownValue else {
            // Unsupported network and/or token, cannot extract derivation index
            return nil
        }

        let blockchain = blockchainNetwork.blockchain
        let derivationPath = blockchainNetwork.derivationPath
        let helper: AccountDerivationPathHelper

        // We don't use `subscript(_:default:)` here despite `AccountDerivationPathHelper` being a value type to
        // prevent this code from breaking in future if `AccountDerivationPathHelper` becomes a reference type
        if let cachedHelper = cachedHelpers[blockchain] {
            helper = cachedHelper
        } else {
            helper = AccountDerivationPathHelper(blockchain: blockchain)
            cachedHelpers[blockchain] = helper
        }

        guard let tokenAccountDerivationNode = helper.extractAccountDerivationNode(from: derivationPath) else {
            // No derivation path and/or account derivation node, cannot extract derivation index
            return nil
        }

        return Int(tokenAccountDerivationNode.rawIndex)
    }
}
