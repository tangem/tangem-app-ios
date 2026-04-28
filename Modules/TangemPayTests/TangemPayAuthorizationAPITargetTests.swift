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
