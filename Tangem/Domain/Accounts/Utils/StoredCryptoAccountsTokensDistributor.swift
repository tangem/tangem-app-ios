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
import TangemMacro

// [REDACTED_TODO_COMMENT]
enum StoredCryptoAccountsTokensDistributor {
    private typealias Cache = [Blockchain: AccountDerivationPathHelper]
    fileprivate typealias DerivationIndex = Int

    /// Distributes tokens among existing crypto accounts based on their derivation indexes.
    /// - Parameters:
    ///  - storedCryptoAccounts: The list of existing crypto accounts to redistribute tokens among. This array is modified in place.
    ///  - additionalTokens: An optional list of tokens that should be distributed among the accounts,
    ///  if accounts with these tokens' derivation indexes exist. If such accounts do not exist, these tokens are added to the `Main` account.
    /// - Returns: Distribution result with account names and redistribution status.
    static func distributeTokens(
        in storedCryptoAccounts: inout [StoredCryptoAccount],
        additionalTokens: [StoredCryptoAccount.Token] = []
    ) -> DistributionResult {
        // First loop (required) - building the list of existing accounts, keyed by their derivation indexes
        var distributionTargets: [DerivationIndex: DistributionTarget] = storedCryptoAccounts
            .reduce(into: [:]) { partialResult, account in
                partialResult[account.derivationIndex] = DistributionTarget(accountName: account.name, tokens: [])
            }

        let hasAdditionalTokens = additionalTokens.isNotEmpty
        var redistributionRecords: [RedistributionRecord] = []

        // Helpers are cached for efficiency since there is limited and finite number of blockchains
        var cachedHelpers: Cache = [:]

        // Second loop (required) - removing tokens that belong to other existing accounts
        for (index, account) in storedCryptoAccounts.enumerated() {
            var updatedAccountTokens: [StoredCryptoAccount.Token] = []

            for token in account.tokens {
                guard let tokenAccountDerivationIndex = extractAccountDerivationIndex(
                    from: token,
                    using: &cachedHelpers,
                    fallbackToMainAccount: false
                ) else {
                    // Unsupported network and/or token, no derivation path and/or account derivation node, etc
                    // Keeping this token in its original account as is
                    updatedAccountTokens.append(token)
                    continue
                }

                if tokenAccountDerivationIndex != account.derivationIndex, distributionTargets[tokenAccountDerivationIndex] != nil {
                    // This token belongs to another existing account, and there exists an account with such derivation index,
                    // moving this token to that account
                    distributionTargets[tokenAccountDerivationIndex]?.tokens.append(token)

                    // Track the source and destination accounts (duplicates are removed later)
                    redistributionRecords.append(
                        RedistributionRecord(
                            source: .account(name: account.name),
                            toAccountDerivationIndex: tokenAccountDerivationIndex
                        )
                    )

                } else {
                    // Keeping this token in its original account as is
                    updatedAccountTokens.append(token)
                }
            }

            storedCryptoAccounts[index] = account.withTokens(updatedAccountTokens)
        }

        guard redistributionRecords.isNotEmpty || hasAdditionalTokens else {
            return .none
        }

        // Third loop (optional) - appending the tokens that were removed in the second loop to their respective accounts
        for (index, account) in storedCryptoAccounts.enumerated() {
            guard let target = distributionTargets[account.derivationIndex] else {
                continue
            }

            storedCryptoAccounts[index] = account.withTokens(account.tokens + target.tokens)
        }

        // Distributing additional tokens if any (optional)
        let additionalResult = add(additionalTokens: additionalTokens, to: &storedCryptoAccounts, using: &cachedHelpers)

        return makeDistributionResult(
            from: redistributionRecords,
            additionalResult: additionalResult,
            distributionTargets: distributionTargets
        )
    }

    // MARK: - Private implementation

    private static func makeDistributionResult(
        from redistributionRecords: [RedistributionRecord],
        additionalResult: AddResult,
        distributionTargets: [DerivationIndex: DistributionTarget]
    ) -> DistributionResult {
        // Combine results from both redistribution passes
        // Note: Additional tokens from external sources (e.g., server) have no "from" account
        var finalRedistributionRecords = redistributionRecords

        if case .redistributionHappened(let records) = additionalResult {
            finalRedistributionRecords.append(contentsOf: records)
        }

        guard finalRedistributionRecords.isNotEmpty else {
            return .none
        }

        // Convert derivation indexes to account names (O(1) lookup)
        let distributionPairs = finalRedistributionRecords.map { record in
            DistributionPair(
                source: record.source,
                toAccountName: distributionTargets[record.toAccountDerivationIndex]?.accountName
            )
        }

        guard distributionPairs.isNotEmpty else {
            return .none
        }

        return .redistributionHappened(
            pairs: distributionPairs.unique()
        )
    }

    /// Adds tokens from `additionalTokens` to existing accounts based on their derivation indexes.
    /// If there are no accounts with the respective derivation indexes, these remaining tokens are added to the `Main` account.
    private static func add(
        additionalTokens: [StoredCryptoAccount.Token],
        to storedCryptoAccounts: inout [StoredCryptoAccount],
        using cachedHelpers: inout Cache
    ) -> AddResult {
        var redistributionRecords: [RedistributionRecord] = []

        guard additionalTokens.isNotEmpty else {
            return .none
        }

        // Find Main account first (needed for consistent record tracking)
        // This is an array index, not a derivation index
        let mainAccountIndex = storedCryptoAccounts.firstIndex { AccountModelUtils.isMainAccount($0.derivationIndex) }
        let mainAccountDerivationIndex = mainAccountIndex.map { storedCryptoAccounts[$0].derivationIndex }

        // These tokens go to the `Main` account because there are no accounts with their derivation indexes
        var remainingTokens: [StoredCryptoAccount.Token] = []

        // First loop (required) - building the list of existing accounts, keyed by their derivation indexes
        var distributionTargets: [DerivationIndex: DistributionTarget] = storedCryptoAccounts
            .reduce(into: [:]) { partialResult, account in
                partialResult[account.derivationIndex] = DistributionTarget(accountName: account.name, tokens: [])
            }

        // Second loop (required) - processing additional tokens
        for token in additionalTokens {
            // `additionalTokens` (i.e. tokens from the `unassignedTokens` DTO field) may contain tokens that were added
            // in a legacy version of the app w/o accounts support on wallets w/o HD wallets support (i.e. w/o derivation paths)
            // Such tokens should always be assigned to the `Main` account; therefore we set `fallbackToMainAccount` to `true` here
            guard let tokenAccountDerivationIndex = extractAccountDerivationIndex(
                from: token,
                using: &cachedHelpers,
                fallbackToMainAccount: true
            ) else {
                // Unsupported network and/or token, no derivation path and/or account derivation node, etc
                // Ignoring this token since there is nothing we can do with it
                continue
            }

            if distributionTargets[tokenAccountDerivationIndex] != nil {
                // This token belongs to an existing account with matching derivation index
                distributionTargets[tokenAccountDerivationIndex]?.tokens.append(token)
                redistributionRecords.append(
                    RedistributionRecord(
                        source: .external,
                        toAccountDerivationIndex: tokenAccountDerivationIndex
                    )
                )
            } else if let mainAccountDerivationIndex {
                // Adding this token to the `Main` account since there is no account with such derivation index
                remainingTokens.append(token)
                redistributionRecords.append(
                    RedistributionRecord(
                        source: .external,
                        toAccountDerivationIndex: mainAccountDerivationIndex
                    )
                )
            }
            // If no Main account exists, token is silently ignored (error case handled below)
        }

        // Third loop (optional) - appending the tokens that were prepared in the second loop to their respective accounts
        for (index, account) in storedCryptoAccounts.enumerated() {
            guard let target = distributionTargets[account.derivationIndex] else {
                continue
            }

            storedCryptoAccounts[index] = account.withTokens(account.tokens + target.tokens)
        }

        // If no tokens need to go to Main account, return early
        guard remainingTokens.isNotEmpty else {
            if redistributionRecords.isNotEmpty {
                return .redistributionHappened(records: redistributionRecords)
            } else {
                return .none
            }
        }

        guard let mainAccountIndex else {
            let message = "No main account found to add \(remainingTokens.count) remaining tokens to"
            assertionFailure(message)
            AccountsLogger.warning(message)
            if redistributionRecords.isNotEmpty {
                return .redistributionHappened(records: redistributionRecords)
            } else {
                return .none
            }
        }

        // Add remaining tokens to Main account
        let mainAccount = storedCryptoAccounts[mainAccountIndex]
        let mainAccountTokens = mainAccount.tokens + remainingTokens
        storedCryptoAccounts[mainAccountIndex] = mainAccount.withTokens(mainAccountTokens)

        return .redistributionHappened(records: redistributionRecords)
    }

    private static func extractAccountDerivationIndex(
        from token: StoredCryptoAccount.Token,
        using cachedHelpers: inout Cache,
        fallbackToMainAccount: Bool
    ) -> DerivationIndex? {
        guard let blockchainNetwork = token.blockchainNetwork.knownValue else {
            // Unsupported network and/or token, cannot extract derivation index
            return nil
        }

        let blockchain = blockchainNetwork.blockchain
        let helper: AccountDerivationPathHelper

        // We don't use `subscript(_:default:)` here despite `AccountDerivationPathHelper` being a value type to
        // prevent this code from breaking in future if `AccountDerivationPathHelper` becomes a reference type
        if let cachedHelper = cachedHelpers[blockchain] {
            helper = cachedHelper
        } else {
            helper = AccountDerivationPathHelper(blockchain: blockchain)
            cachedHelpers[blockchain] = helper
        }

        if let derivationPath = blockchainNetwork.derivationPath {
            do {
                let tokenAccountDerivationNode = try helper.extractAccountDerivationNode(from: derivationPath)
                return Int(tokenAccountDerivationNode.rawIndex)
            } catch {
                // Ugly and explicit switch here due to https://github.com/swiftlang/swift/issues/74555 ([REDACTED_INFO])
                switch error {
                case .insufficientNodes,
                     .accountsUnavailableForBlockchain:
                    // Both of these errors must be unconditionally fallback to the Main account since only the
                    // Main account can handle malformed derivation paths and/or blockchains w/o accounts support
                    return AccountModelUtils.mainAccountDerivationIndex
                }
            }
        }

        return fallbackToMainAccount ? AccountModelUtils.mainAccountDerivationIndex : nil
    }
}

// MARK: - Auxiliary public types

extension StoredCryptoAccountsTokensDistributor {
    @CaseFlagable
    enum DistributionResult {
        case none
        case redistributionHappened(pairs: [DistributionPair])
    }

    struct DistributionPair: Hashable {
        enum Source: Hashable {
            /// Token redistributed from an existing account (nil name = Main with default name)
            case account(name: String?)
            /// Legacy token from outside the account system (e.g., unassigned tokens from server)
            case external
        }

        let source: Source
        let toAccountName: String?
    }
}

// MARK: - Auxiliary private types

private extension StoredCryptoAccountsTokensDistributor {
    struct RedistributionRecord: Hashable {
        let source: DistributionPair.Source
        let toAccountDerivationIndex: DerivationIndex
    }

    struct DistributionTarget {
        let accountName: String?
        var tokens: [StoredCryptoAccount.Token]
    }

    enum AddResult {
        case none
        case redistributionHappened(records: [RedistributionRecord])
    }
}
