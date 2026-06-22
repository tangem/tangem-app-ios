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

final class TransactionHistoryUpdater {
    private let scheduledUpdatesStorage: TransactionHistoryScheduledUpdatesStorage

    init(scheduledUpdatesStorage: TransactionHistoryScheduledUpdatesStorage) {
        self.scheduledUpdatesStorage = scheduledUpdatesStorage
    }

    func updateHistoryIfNeeded(
        featuresPublisher: AnyPublisher<[WalletModelFeature], Never>,
        updateToken: AnyHashable
    ) async {
        do {
            let transactionHistoryProviders = try await featuresPublisher
                .first() // [REDACTED_TODO_COMMENT]
                .map { features in
                    return features.compactMap { feature in
                        switch feature {
                        case .transactionHistory(let transactionHistoryProvider):
                            return transactionHistoryProvider
                        case .dynamicAddresses,
                             .nft:
                            return nil
                        }
                    }
                }
                .async()

            // 1. `syncInitial`/`syncDelta` calls are re-entrant and synchronized, so they can be safely called multiple times within the loop
            // 2. In almost all cases there is only one, single provider, so `TaskGroup` is an overkill here - simple `for` loop is enough
            for provider in transactionHistoryProviders {
                let shouldScheduleUpdate = await scheduledUpdatesStorage.shouldScheduleUpdate(
                    updateToken: updateToken,
                    providerId: provider.id.toAnyHashable()
                )

                guard shouldScheduleUpdate else {
                    // Update with this provider for this update iteration (determined by the `updateToken`) is already scheduled, skip it
                    continue
                }

                Task {
                    // Initial and delta syncs are mutually exclusive, and delta sync can start only after initial sync is completed,
                    // so we can safely trigger both types of syncs here without any additional checks/synchronization
                    await provider.syncInitial()
                    await provider.syncDelta()
                }
            }
        } catch {
            // [REDACTED_TODO_COMMENT]
            AppLogger.error(self, "Failed to update V2 transaction history", error: error)
        }
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension TransactionHistoryUpdater: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
