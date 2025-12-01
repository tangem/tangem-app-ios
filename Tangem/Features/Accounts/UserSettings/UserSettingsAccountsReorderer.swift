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
        oldRows: [UserSettingsAccountRowViewData],
        newRows: [UserSettingsAccountRowViewData]
    ) {
        let oldIds = oldRows.map(\.id).toSet()
        let newIds = newRows.map(\.id)

        // We are interested in order changes only, therefore all structural changes of the list are filtered out
        // (i.e. the nil value is returned to cancel pending reorder task, if any)
        let orderedIds = oldIds == newIds.toSet()
            ? newIds
            : nil

        schedulePendingReorder(orderedIds)
    }

    private func schedulePendingReorder(_ orderedIds: [AnyHashable]?) {
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

        // Request additional execution time from system
        backgroundTaskHandle = BackgroundTaskWrapper(taskName: "com.tangem.UserSettingsAccountsReorderer_\(UUID().uuidString)") {
            pendingReorderTask.cancel()
        }

        self.pendingReorderTask = pendingReorderTask
    }
}
