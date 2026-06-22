//
//  TransactionHistoryScheduledUpdatesStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Should be shared per user-wallet: deduplicates transaction history v2 update triggers
///  so the same provider isn't re-synced more than once within a single update iteration.
actor TransactionHistoryScheduledUpdatesStorage {
    private var scheduledUpdateTasks: Set<ScheduledUpdateTaskKey> = []

    func shouldScheduleUpdate(updateToken: AnyHashable, providerId: AnyHashable) -> Bool {
        return scheduledUpdateTasks
            .insert(ScheduledUpdateTaskKey(updateToken: updateToken, providerId: providerId))
            .inserted
    }
}

// MARK: - Auxiliary types

private extension TransactionHistoryScheduledUpdatesStorage {
    struct ScheduledUpdateTaskKey: Hashable {
        let updateToken: AnyHashable
        let providerId: AnyHashable
    }
}
