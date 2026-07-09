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

            guard transactionHistoryProviders.isNotEmpty else {
                return
            }

            // `syncInitial`/`syncDelta` are run in a fire-and-forget manner, so the caller doesn't need to await them
            Task { [scheduledUpdatesStorage] in
                // But we need to await all `syncInitial`/`syncDelta` to perform the scheduled updates storage cleanup (`removeScheduledUpdate` calls)
                let scheduledProviderIds = await withTaskGroup { taskGroup in
                    var scheduledProviderIds: [AnyHashable] = []

                    for provider in transactionHistoryProviders {
                        let providerId = provider.id.toAnyHashable()

                        guard await scheduledUpdatesStorage.shouldScheduleUpdate(
                            updateToken: updateToken,
                            providerId: providerId
                        ) else {
                            // Update with this provider for this update iteration (determined by the `updateToken`) is already scheduled, skipping it
                            continue
                        }

                        scheduledProviderIds.append(providerId)

                        taskGroup.addTask {
                            // Initial and delta syncs are mutually exclusive, and delta sync can start only after initial sync is completed,
                            // so we can safely trigger both types of syncs here without any additional checks/synchronization
                            await provider.syncInitial()
                            await provider.syncDelta()
                        }
                    }

                    return scheduledProviderIds
                }

                // Marking the providers as having completed their updates for this update iteration (determined by the `updateToken` and `providerId`)
                for providerId in scheduledProviderIds {
                    await scheduledUpdatesStorage.removeScheduledUpdate(updateToken: updateToken, providerId: providerId)
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
