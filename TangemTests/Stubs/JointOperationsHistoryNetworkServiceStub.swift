//
//  JointOperationsHistoryNetworkServiceStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem

final class JointOperationsHistoryNetworkServiceStub: JointOperationsHistoryNetworkService, Sendable {
    private struct State {
        var initialCallsCount = 0
        var deltaCallsCount = 0
    }

    private let error: (any Error & Sendable)?
    private let state = OSAllocatedUnfairLock(initialState: State())

    var initialCallsCount: Int {
        state.withLock(\.initialCallsCount)
    }

    var deltaCallsCount: Int {
        state.withLock(\.deltaCallsCount)
    }

    init(error: (any Error & Sendable)?) {
        self.error = error
    }

    func syncInitial() async throws {
        state.withLock { $0.initialCallsCount += 1 }
        try throwErrorIfAny()
    }

    func syncDelta() async throws {
        state.withLock { $0.deltaCallsCount += 1 }
        try throwErrorIfAny()
    }

    private func throwErrorIfAny() throws {
        if let error {
            throw error
        }
    }
}
