//
//  UserSettingsAccountsReorderer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class UserSettingsAccountsReorderer {
    private let accountModelsReorderer: AccountModelsReordering
    private let debounceInterval: TimeInterval
    private var pendingReorderTask: Task<Void, Never>?

    init(
        accountModelsReorderer: AccountModelsReordering,
        debounceInterval: TimeInterval
    ) {
        self.accountModelsReorderer = accountModelsReorderer
        self.debounceInterval = debounceInterval
    }

    func schedulePendingReorderIfNeeded(
        oldRows: [UserSettingsAccountsViewModel.AccountRow],
        newRows: [UserSettingsAccountsViewModel.AccountRow],
        persistentIdentifierProvider: (_ accountRow: UserSettingsAccountsViewModel.AccountRow) -> any AccountModelPersistentIdentifierConvertible
    ) {
        let newPersistentIdentifiers = newRows
            .map { persistentIdentifierProvider($0) }

        let newPersistentIdentifiersToCompare = newPersistentIdentifiers
            .map { $0.toAnyHashable() }

        let oldPersistentIdentifiersToCompare = oldRows
            .map { persistentIdentifierProvider($0).toAnyHashable() }

        // We are only interested in order changes, therefore all structural changes to the list are filtered out
        // (i.e., `shouldSchedulePendingReorder` is false to cancel any pending reorder tasks, if any)
        let shouldSchedulePendingReorder = oldPersistentIdentifiersToCompare.count == newPersistentIdentifiersToCompare.count
            && oldPersistentIdentifiersToCompare.toSet() == newPersistentIdentifiersToCompare.toSet()
            && oldPersistentIdentifiersToCompare != newPersistentIdentifiersToCompare

        schedulePendingReorder(shouldSchedulePendingReorder ? newPersistentIdentifiers : nil)
    }

    private func schedulePendingReorder(_ orderedPersistentIdentifiers: [any AccountModelPersistentIdentifierConvertible]?) {
        ensureOnMainQueue()

        // Cancel previous pending reorder task, if any
        pendingReorderTask?.cancel()

        guard let orderedPersistentIdentifiers else {
            return
        }

        var backgroundTaskHandle: BackgroundTaskWrapper?
        let debounceInterval = debounceInterval

        // Strong capture of `accountModelsReorderer` here because this task may get executed
        // after deallocation of the `UserSettingsAccountsReorderer` instance
        let pendingReorderTask = Task { [reorderer = accountModelsReorderer] in
            do {
                try await Task.sleep(for: .seconds(debounceInterval))
                try await reorderer.reorder(orderedIdentifiers: orderedPersistentIdentifiers)
                Analytics.log(.walletSettingsLongtapAccountsOrder)
                AccountsLogger.info("Reordering completed")
            } catch {
                AccountsLogger.error("Reordering failed due to error: ", error: error)
            }

            withExtendedLifetime(backgroundTaskHandle) {}
        }

        // Request additional execution time from system in case the app goes to background
        backgroundTaskHandle = BackgroundTaskWrapper(taskName: "com.tangem.UserSettingsAccountsReorderer_\(UUID().uuidString)") {
            pendingReorderTask.cancel()
        }

        self.pendingReorderTask = pendingReorderTask
    }
}
