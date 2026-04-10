//
//  CommonWalletTokenAutoSyncPersister.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import BlockchainSdk

final class CommonWalletTokenAutoSyncPersister: WalletTokenAutoSyncPersister {
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

private extension CommonWalletTokenAutoSyncPersister {
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
                AppLogger.tag("WalletTokenAutoSync").error("Failed to sync discovered tokens after \(attempt + 1) attempts", error: error)
                return
            }

            AppLogger.tag("WalletTokenAutoSync").debug("Token list not ready, retry \(attempt + 1)/\(Constants.maxSyncRetries)")

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

    func waitForTokenListReady(accountModelsManager: AccountModelsManager) async throws {
        try await accountModelsManager
            .cryptoAccountModelsPublisher
            .setFailureType(to: WalletTokenAutoSyncError.self)
            .flatMapLatest { cryptoAccountModels -> AnyPublisher<Void, WalletTokenAutoSyncError> in
                guard cryptoAccountModels.isNotEmpty else {
                    return Fail(error: .userTokenListNotReady).eraseToAnyPublisher()
                }

                return cryptoAccountModels
                    .map { $0.userTokensManager.userTokensPublisher }
                    .combineLatest()
                    .map { _ in () }
                    .setFailureType(to: WalletTokenAutoSyncError.self)
                    .eraseToAnyPublisher()
            }
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
            AppLogger.tag("WalletTokenAutoSync").debug("No main crypto account found, skipping token persistence")
            return
        }

        let newTokens = discoveredTokens.filter { token in
            !mainAccount.userTokensManager.contains(token, derivationInsensitive: false)
        }

        guard newTokens.isNotEmpty else {
            AppLogger.tag("WalletTokenAutoSync").debug("No new tokens to add, all already present")
            return
        }

        do {
            try Task.checkCancellation()
            try mainAccount.userTokensManager.update(itemsToRemove: [], itemsToAdd: newTokens)
            AppLogger.tag("WalletTokenAutoSync").debug("Added \(newTokens.count) new tokens to main account")
        } catch is CancellationError {
            AppLogger.tag("WalletTokenAutoSync").debug("Token persistence cancelled before account update")
        } catch {
            AppLogger.tag("WalletTokenAutoSync").error("Failed to add tokens to main account", error: error)
        }
    }
}

// MARK: - Constants

private extension CommonWalletTokenAutoSyncPersister {
    enum Constants {
        static let maxSyncRetries = 5
        static let syncTimeoutSeconds = 3
        static let retryDelay: Duration = .seconds(1)
    }
}
