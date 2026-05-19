//
//  TransactionHistorySyncing.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol TransactionHistorySyncing {
    var state: TransactionHistorySyncState { get async }
    var stateUpdates: AsyncStream<TransactionHistorySyncState> { get }

    func syncInitial() async
    func syncDelta() async
    func syncUserInitiated(_ kind: UserInitiatedSyncKind) async
}
