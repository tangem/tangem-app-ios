//
//  WalletTokenAutoSyncStateActor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

actor WalletTokenAutoSyncStateActor {
    private var runningTasks: [UserWalletId: Task<Void, Never>] = [:]

    func startIfPossible(
        userWalletId: UserWalletId,
        priority: TaskPriority = .utility,
        operation: @escaping @Sendable () async -> Void
    ) throws {
        if runningTasks[userWalletId] != nil {
            throw WalletTokenAutoSyncError.syncAlreadyInProgress
        }

        let syncTask = Task(priority: priority) { [weak self] in
            await operation()
            await self?.removeTask(userWalletId: userWalletId)
        }

        runningTasks[userWalletId] = syncTask
    }

    func cancelAndUnregister(userWalletId: UserWalletId) {
        runningTasks[userWalletId]?.cancel()
        removeTask(userWalletId: userWalletId)
    }
}

private extension WalletTokenAutoSyncStateActor {
    func removeTask(userWalletId: UserWalletId) {
        runningTasks.removeValue(forKey: userWalletId)
    }
}
