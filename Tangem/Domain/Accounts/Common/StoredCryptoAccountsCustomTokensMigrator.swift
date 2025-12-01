//
//  StoredCryptoAccountsCustomTokensMigrator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

// [REDACTED_TODO_COMMENT]
/// Async port of custom tokens migration logic from `CommonUserTokenListManager`.
struct StoredCryptoAccountsCustomTokensMigrator {
    private typealias TokenToMigrate = TokenMigrationInfo<String?>
    private typealias MigratedToken = TokenMigrationInfo<BlockchainSdk.Token>

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    /// Performs migration of custom tokens (i.e. tokens without identifier) in the provided stored crypto accounts.
    /// - Parameters:
    ///     - storedCryptoAccounts: The list of existing crypto accounts to redistribute tokens among. This array is modified in place.
    /// - Returns: `true` if any custom tokens were migrated, `false` otherwise.
    func migrateTokensIfNeeded(in storedCryptoAccounts: inout [StoredCryptoAccount]) async -> Bool {
        var tokensToMigrate: [TokenToMigrate] = []

        for (accountIndex, account) in storedCryptoAccounts.enumerated() {
            for (tokenIndex, token) in account.tokens.enumerated() {
                guard
                    token.id == nil, // A custom token (i.e. token w/o identifier), we should attempt to migrate it
                    let blockchainNetwork = token.blockchainNetwork.knownValue // We can't migrate tokens we know nothing about
                else {
                    continue
                }

                let tokenToMigrate = TokenToMigrate(
                    accountIndex: accountIndex,
                    tokenIndex: tokenIndex,
                    blockchainNetwork: blockchainNetwork,
                    value: token.contractAddress
                )
                tokensToMigrate.append(tokenToMigrate)
            }
        }

        let migratedTokens = await getMigratedTokens(for: tokensToMigrate)
        let (updatedAccounts, isDirty) = apply(migratedTokens: migratedTokens, to: storedCryptoAccounts)

        if isDirty {
            storedCryptoAccounts = updatedAccounts
        }

        return isDirty
    }

    private func getMigratedTokens(for tokensToMigrate: [TokenToMigrate]) async -> [MigratedToken] {
        return await withTaskGroup(of: MigratedToken?.self) { group in
            for tokenToMigrate in tokensToMigrate {
                let blockchainNetwork = tokenToMigrate.blockchainNetwork
                let request = CoinsList.Request(
                    supportedBlockchains: [blockchainNetwork.blockchain],
                    contractAddress: tokenToMigrate.value
                )
                group.addTask {
                    let coinModels = await getFilteredCoinModels(request: request)
                    let allRemoteTokens = coinModels.flatMap(\.items).compactMap(\.token)

                    guard let remoteToken = allRemoteTokens.first else {
                        return nil
                    }

                    return MigratedToken(
                        accountIndex: tokenToMigrate.accountIndex,
                        tokenIndex: tokenToMigrate.tokenIndex,
                        blockchainNetwork: blockchainNetwork,
                        value: remoteToken
                    )
                }
            }

            return await group.reduce(into: []) { partialResult, migratedToken in
                if let migratedToken {
                    partialResult.append(migratedToken)
                }
            }
        }
    }

    private func getFilteredCoinModels(request: CoinsList.Request) async -> [CoinModel] {
        let response: CoinsList.Response

        do {
            response = try await tangemApiService.loadCoins(requestModel: request)
        } catch {
            // Original implementation from `CommonUserTokenListManager` also ignores errors here
            return []
        }

        let mapper = CoinsResponseMapper(supportedBlockchains: request.supportedBlockchains)
        let coinModels = mapper.mapToCoinModels(response)

        guard let contractAddress = request.contractAddress else {
            return coinModels
        }

        return coinModels.compactMap { coinModel in
            let filteredItems = coinModel.items.filter { item in
                item.token?.contractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
            }

            guard filteredItems.isNotEmpty else {
                return nil
            }

            return CoinModel(
                id: coinModel.id,
                name: coinModel.name,
                symbol: coinModel.symbol,
                items: filteredItems
            )
        }
    }

    private func apply(
        migratedTokens: [MigratedToken],
        to existingCryptoAccounts: [StoredCryptoAccount]
    ) -> (accounts: [StoredCryptoAccount], isDirty: Bool) {
        var updatedCryptoAccounts = existingCryptoAccounts
        var isDirty = false

        for migratedToken in migratedTokens {
            let accountIndex = migratedToken.accountIndex
            let account = updatedCryptoAccounts[accountIndex]
            let updatedTokens = account
                .tokens
                .enumerated()
                .map { tokenIndex, existingToken in
                    guard tokenIndex == migratedToken.tokenIndex else {
                        return existingToken
                    }

                    isDirty = true

                    return StoredEntryConverter.convertFromBSDKToken(migratedToken.value, in: migratedToken.blockchainNetwork)
                }

            updatedCryptoAccounts[accountIndex] = account.withTokens(updatedTokens)
        }

        return (updatedCryptoAccounts, isDirty)
    }
}

// MARK: - Auxiliary types

private extension StoredCryptoAccountsCustomTokensMigrator {
    struct TokenMigrationInfo<T> {
        let accountIndex: Int
        let tokenIndex: Int
        let blockchainNetwork: BlockchainNetwork
        let value: T
    }
}
