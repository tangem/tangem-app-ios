//
//  BalanceRefreshSpy.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class BalanceRefreshSpy: Sendable {
    private let refreshes = TestSignal<Void>()

    var callsCount: Int {
        refreshes.recorded.count
    }

    func refresh() {
        refreshes.send()
    }

    @MainActor
    func waitForCalls(_ count: Int) async throws {
        try await refreshes.waitForCount(count)
    }
}
