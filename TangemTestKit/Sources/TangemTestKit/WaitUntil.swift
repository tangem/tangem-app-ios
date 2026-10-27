//
//  WaitUntil.swift
//  TangemTestKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing

@MainActor
public func waitUntil(timeout: Duration = .seconds(5), _ condition: () -> Bool) async {
    let deadline = ContinuousClock.now + timeout

    while !condition() {
        if ContinuousClock.now >= deadline {
            Issue.record("waitUntil timed out")
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(10))
        } catch {
            return
        }
    }
}
