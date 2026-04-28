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
    private let tokenA = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1111111111111111111111111111111111111111111111111111MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM2222222222222222222222222222222222222222222222222222ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
    private let tokenB = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"

    @Test(".hash collapses these two distinct tokens to the same value (the bug)")
    func hashCollidesOnPair() {
        #expect(tokenA != tokenB)
        #expect(tokenA.hash == tokenB.hash)
    }

    @Test("Target produces distinct idempotency keys for those same tokens")
    func differentTokensProduceDifferentKeys() {
        #expect(idempotencyKey(for: tokenA) != idempotencyKey(for: tokenB))
    }

    @Test("Target produces the same idempotency key for the same refresh token")
    func sameTokenProducesSameKey() {
        #expect(idempotencyKey(for: tokenA) == idempotencyKey(for: tokenA))
    }

    private func idempotencyKey(for refreshToken: String) -> String? {
        let target = TangemPayAuthorizationAPITarget(
            target: .refreshTokens(request: .init(refreshToken: refreshToken)),
            apiType: .prod
        )
        return target.headers?["Idempotency-Key"]
    }
}
