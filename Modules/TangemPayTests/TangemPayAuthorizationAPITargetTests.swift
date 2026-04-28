//
//  TangemPayAuthorizationAPITargetTests.swift
//  TangemPayTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPay

@Suite("TangemPayAuthorizationAPITarget idempotency key")
struct TangemPayAuthorizationAPITargetTests {
    @Test(".hash collapses the colliding pair to the same value (the bug)")
    func hashCollidesOnPair() {
        let (a, b) = collidingPair()
        #expect(a != b)
        #expect(a.hash == b.hash)
    }

    @Test("Target produces distinct idempotency keys for that same pair")
    func differentTokensProduceDifferentKeys() {
        let (a, b) = collidingPair()
        #expect(idempotencyKey(for: a) != idempotencyKey(for: b))
    }

    @Test("Target produces the same idempotency key for the same refresh token")
    func sameTokenProducesSameKey() {
        let (a, _) = collidingPair()
        #expect(idempotencyKey(for: a) == idempotencyKey(for: a))
    }

    private func collidingPair() -> (String, String) {
        let head = String(repeating: "A", count: 32)
        let middle = String(repeating: "M", count: 32)
        let tail = String(repeating: "Z", count: 32)
        let a = head
            + String(repeating: "1", count: 52)
            + middle
            + String(repeating: "2", count: 52)
            + tail
        let b = head
            + String(repeating: "X", count: 52)
            + middle
            + String(repeating: "Y", count: 52)
            + tail
        return (a, b)
    }

    private func idempotencyKey(for refreshToken: String) -> String? {
        let target = TangemPayAuthorizationAPITarget(
            target: .refreshTokens(request: .init(refreshToken: refreshToken)),
            apiType: .prod
        )
        return target.headers?["Idempotency-Key"]
    }
}
