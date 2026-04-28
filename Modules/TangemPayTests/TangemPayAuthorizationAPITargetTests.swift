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
    @Test(".hash collides: two strings differing only in filler bytes")
    func hashCollidesOnFillerTwin() {
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
        #expect(a != b)
        #expect(a.hash == b.hash)
    }

    @Test(".hash collides: two visibly-different long strings")
    func hashCollidesOnVisiblyDifferentStrings() {
        let head = String(repeating: "A", count: 32)
        let middle = String(repeating: "M", count: 32)
        let tail = String(repeating: "Z", count: 32)
        let a = head
            + String(repeating: "1", count: 52)
            + middle
            + String(repeating: "2", count: 52)
            + tail
        let b = head
            + "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            + middle
            + "zyxwvutsrqponmlkjihgfedcbaZYXWVUTSRQPONMLKJIHGFEDCBA"
            + tail
        #expect(a != b)
        #expect(a.hash == b.hash)
    }

    @Test("Different refresh tokens produce different idempotency keys")
    func differentTokensProduceDifferentKeys() {
        let a = "refresh-token-a"
        let b = "refresh-token-b"
        #expect(idempotencyKey(for: a) != idempotencyKey(for: b))
    }

    @Test("Same refresh token produces the same idempotency key")
    func sameTokenProducesSameKey() {
        let token = "OGM3ZjRkYjctYjE0Mi00MWU4LWIwYWQtMWI5YmYzZmVjZGE0OnM0bFRpSTc1QjNYXzl3Y29NeXdOS0RjRi16cW1oUFM3VFEtU2NUbzlSVlU"
        #expect(idempotencyKey(for: token) == idempotencyKey(for: token))
    }

    private func idempotencyKey(for refreshToken: String) -> String? {
        let target = TangemPayAuthorizationAPITarget(
            target: .refreshTokens(request: .init(refreshToken: refreshToken)),
            apiType: .prod
        )
        return target.headers?["Idempotency-Key"]
    }
}
