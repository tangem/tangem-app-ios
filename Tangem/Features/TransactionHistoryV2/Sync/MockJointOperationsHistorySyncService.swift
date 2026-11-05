//
//  MockJointOperationsHistorySyncService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MockJointOperationsHistorySyncService {}

// MARK: - JointOperationsHistorySyncing protocol conformance

extension MockJointOperationsHistorySyncService: JointOperationsHistorySyncing {
    var state: TransactionHistorySyncState {
        .idle(.neverSynced)
    }

    var stateUpdates: AsyncStream<TransactionHistorySyncState> {
        AsyncStream { continuation in
            continuation.yield(.idle(.neverSynced))
            continuation.finish()
        }
    }

    func syncInitial() async {}

    func syncDelta() async {}

    func syncUserInitiated(_ kind: UserInitiatedSyncKind) async {}
}
