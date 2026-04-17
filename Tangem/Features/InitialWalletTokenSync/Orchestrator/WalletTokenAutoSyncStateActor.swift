//
//  WalletTokenAutoSyncStateActor.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

actor WalletTokenAutoSyncStateActor {
    private var syncTasks: [String: Task<Void, Never>] = [:]

    func executeIfPossible(
        userWalletId: UserWalletId,
        priority: TaskPriority = .utility,
        operation: @escaping @Sendable () async -> Void
    ) throws {
        let key = userWalletId.stringValue

        guard syncTasks[key] == nil else {
            throw WalletTokenAutoSyncError.syncAlreadyInProgress
        }

        syncTasks[key] = Task(priority: priority) { [weak self] in
            await operation()
            await self?.unregister(userWalletId: userWalletId)
        }
    }

    func unregister(userWalletId: UserWalletId) {
        syncTasks.removeValue(forKey: userWalletId.stringValue)
    }

    func cancelAndUnregister(userWalletId: UserWalletId) {
        let key = userWalletId.stringValue
        syncTasks[key]?.cancel()
        syncTasks.removeValue(forKey: key)
    }
}
