//
//  CommonWalletAssetsDiscoveryPersister.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

final class CommonWalletAssetsDiscoveryPersister: WalletAssetsDiscoveryPersister {
    func syncDiscoveredTokensWithAccounts(
        discoveredTokens: [TokenItem],
        accountModelsManager: AccountModelsManager
    ) async {
        await syncDiscoveredTokensWithAccounts(
            discoveredTokens: discoveredTokens,
            accountModelsManager: accountModelsManager,
            attempt: 0
        )
    }
}

// MARK: - Private

private extension CommonWalletAssetsDiscoveryPersister {
    func syncDiscoveredTokensWithAccounts(
        discoveredTokens: [TokenItem],
        accountModelsManager: AccountModelsManager,
        attempt: Int
    ) async {
        do {
            try await waitForTokenListReady(accountModelsManager: accountModelsManager)

            addNewTokensToMainAccount(
                discoveredTokens: discoveredTokens,
                accountModelsManager: accountModelsManager
            )
        } catch is CancellationError {
            return
        } catch {
            guard attempt < Constants.maxSyncRetries, !Task.isCancelled else {
                AssetsDiscoveryLogger.error("Failed to sync discovered tokens after \(attempt + 1) attempts", error: error)
                return
            }

            AssetsDiscoveryLogger.debug("Token list not ready, retry \(attempt + 1)/\(Constants.maxSyncRetries)")

            try? await Task.sleep(for: Constants.retryDelay)

            // Check cancellation after retry delay to avoid unnecessary retries
            guard !Task.isCancelled else { return }

            await syncDiscoveredTokensWithAccounts(
                discoveredTokens: discoveredTokens,
                accountModelsManager: accountModelsManager,
                attempt: attempt + 1
            )
        }
    }

    /// Ensures main account token list is initialized before auto-sync.
    func waitForTokenListReady(accountModelsManager: AccountModelsManager) async throws {
        guard let mainAccount = accountModelsManager.cryptoAccountModels.first(where: { $0.isMainAccount }) else {
            throw WalletAssetsDiscoveryError.userTokenListNotReady
        }

        try await mainAccount
            .userTokensManager
            .userTokensPublisher
            .setFailureType(to: WalletAssetsDiscoveryError.self)
            .prefix(1)
            .mapToVoid()
            .timeout(
                .seconds(Constants.syncTimeoutSeconds),
                scheduler: DispatchQueue.main,
                customError: { .userTokenListNotReady }
            )
            .async()
    }

    func addNewTokensToMainAccount(
        discoveredTokens: [TokenItem],
        accountModelsManager: AccountModelsManager
    ) {
        guard let mainAccount = accountModelsManager.cryptoAccountModels.first(where: { $0.isMainAccount }) else {
            AssetsDiscoveryLogger.debug("No main crypto account found, skipping token persistence")
            return
        }

        let newTokens = discoveredTokens.filter { token in
            !mainAccount.userTokensManager.contains(token, derivationInsensitive: false)
        }

        guard newTokens.isNotEmpty else {
            AssetsDiscoveryLogger.debug("No new tokens to add, all already present")
            return
        }

        do {
            try Task.checkCancellation()
            try mainAccount.userTokensManager.update(itemsToRemove: [], itemsToAdd: newTokens)
            AssetsDiscoveryLogger.debug("Added \(newTokens.count) new tokens to main account")
        } catch is CancellationError {
            AssetsDiscoveryLogger.debug("Token persistence cancelled before account update")
        } catch {
            AssetsDiscoveryLogger.error("Failed to add tokens to main account", error: error)
        }
    }
}

// MARK: - Constants

private extension CommonWalletAssetsDiscoveryPersister {
    enum Constants {
        static let maxSyncRetries = 5
        static let syncTimeoutSeconds = 3
        static let retryDelay: Duration = .seconds(1)
    }
}
