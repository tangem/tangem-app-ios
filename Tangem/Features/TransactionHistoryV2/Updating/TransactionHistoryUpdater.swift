//
//  TransactionHistoryUpdater.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// Shared per user wallet: deduplicates transaction history v2 update triggers so the shared provider isn't
/// re-synced more than once within a single update iteration. Wallet models are updated in batches and all of
/// them reach the same provider, so without this every wallet model would trigger its own sync.
actor TransactionHistoryUpdater {
    private var scheduledUpdateTokens: Set<AnyHashable> = []

    func updateHistoryIfNeeded(
        featuresPublisher: some Publisher<[WalletModelFeature], Never>,
        updateToken: AnyHashable
    ) async {
        do {
            let transactionHistoryProvider = try await featuresPublisher
                .first() // [REDACTED_TODO_COMMENT]
                .async()
                .transactionHistoryProvider

            // The provider is absent when the feature is disabled or this token has no express support
            guard let transactionHistoryProvider else {
                return
            }

            // Update for this update iteration (determined by the `updateToken`) is already scheduled, skipping it
            guard scheduledUpdateTokens.insert(updateToken).inserted else {
                return
            }

            // `syncInitial`/`syncDelta` are run in a fire-and-forget manner, so the caller doesn't need to await them
            // Bare `Task` is used here intentionally to mutate actor properties from the same actor context
            Task {
                // But we do await them here to mark this update iteration as completed only once it has
                // actually finished syncing

                // Initial and delta syncs are mutually exclusive, and delta sync can start only after initial sync is completed,
                // so we can safely trigger both types of syncs here without any additional checks/synchronization
                await transactionHistoryProvider.syncInitial()
                await transactionHistoryProvider.syncDelta()

                scheduledUpdateTokens.remove(updateToken)
            }
        } catch {
            // [REDACTED_TODO_COMMENT]
            AppLogger.error(self, "Failed to update V2 transaction history", error: error)
        }
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension TransactionHistoryUpdater: CustomStringConvertible {
    nonisolated var description: String {
        objectDescription(self)
    }
}
