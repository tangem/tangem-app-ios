//
//  JointOperationsHistoryDeltaSyncingStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem

final class JointOperationsHistoryDeltaSyncingStub: JointOperationsHistoryDeltaSyncing {
    let syncDeltaCalls: AsyncStream<Void>

    private let syncDeltaCallsContinuation: AsyncStream<Void>.Continuation
    private let callsCount = OSAllocatedUnfairLock(initialState: 0)

    var syncDeltaCallsCount: Int {
        callsCount.withLock { $0 }
    }

    init() {
        (syncDeltaCalls, syncDeltaCallsContinuation) = AsyncStream<Void>.makeStream()
    }

    func syncDelta() async {
        callsCount.withLock { $0 += 1 }
        syncDeltaCallsContinuation.yield()
    }
}
