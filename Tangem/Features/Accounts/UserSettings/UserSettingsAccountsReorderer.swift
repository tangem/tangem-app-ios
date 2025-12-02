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
    private var pendingReorderTask: AnyCancellable?

    init(
        accountModelsReorderer: AccountModelsReordering,
        debounceInterval: TimeInterval
    ) {
        self.accountModelsReorderer = accountModelsReorderer
        self.debounceInterval = debounceInterval
    }

    func schedulePendingReorderIdNeeded(
        oldRows: [UserSettingsAccountsViewModel._UserSettingsAccountRowViewData],
        newRows: [UserSettingsAccountsViewModel._UserSettingsAccountRowViewData]
    ) {
        let oldPersistentIdentifiers = oldRows
            .map { $0.persId.toPersistentIdentifier().toAnyHashable() }
            .toSet()

        let newPersistentIdentifiers = newRows
            .map { $0.persId }

        // We are only interested in order changes, therefore all structural changes to the list are filtered out
        // (i.e., nil value is returned to cancel any pending reorder tasks, if any)
        let orderedIds = oldPersistentIdentifiers == newPersistentIdentifiers.map { $0.toPersistentIdentifier().toAnyHashable() }.toSet()
            ? newPersistentIdentifiers
            : nil

        schedulePendingReorder(orderedIds)
    }

    private func schedulePendingReorder(_ orderedIds: [any AccountModelPersistentIdentifierConvertible]?) {
        ensureOnMainQueue()

        pendingReorderTask?.cancel()

        guard let orderedIds else {
            return
        }

        var backgroundTaskHandle: BackgroundTaskWrapper?

        // Strong capture of `accountModelsReorderer` here because this task may get executed
        // after deallocation of the `UserSettingsAccountsReorderer` instance
        let pendingReorderTask = Task { [reorderer = accountModelsReorderer] in
            do {
                try await Task.sleep(seconds: debounceInterval)
                try await reorderer.reorder(orderedIdentifiers: orderedIds)
                AccountsLogger.info("Reordering completed")
            } catch {
                AccountsLogger.error("Reordering failed due to error: ", error: error)
            }

            withExtendedLifetime(backgroundTaskHandle) {}
        }.eraseToAnyCancellable()

        // Request additional execution time from system in case the app goes to background
        backgroundTaskHandle = BackgroundTaskWrapper(taskName: "com.tangem.UserSettingsAccountsReorderer_\(UUID().uuidString)") {
            pendingReorderTask.cancel()
        }

        self.pendingReorderTask = pendingReorderTask
    }
}
