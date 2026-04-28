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

    private static let realRefreshTokens: [(token: String, oldKey: Int)] = [
        ("MjI4OWU3MjQtNjhmZi00NDc2LTg1ODAtYmRhZTM5ZDMwZTk2OkJmd19PZmdRM2hOcEJxYnRlaXpsTFFBcVZKem93MTNVdENTX3B0OWt3bGM", 7183303684225034793),
        ("MjI4OWU3MjQtNjhmZi00NDc2LTg1ODAtYmRhZTM5ZDMwZTk2OkV0VTV2dXZ3WG9FTE9sWTU5Y040YnlZYkl0MlhjNWlOOXdsaE82bXFoNDA", 3231548018204530287),
        ("MjI4OWU3MjQtNjhmZi00NDc2LTg1ODAtYmRhZTM5ZDMwZTk2OlZZSGhaY0FIaVk3ZTdVVEQ2bU1NVWhhUm5reUhwbTdJVkN6YkhGRU1iME0", 2647985486561411084),
        ("MjI4OWU3MjQtNjhmZi00NDc2LTg1ODAtYmRhZTM5ZDMwZTk2OmVDN3ZhTlpBQUdmUlJtVldzWU5rQ3BvOTlDTnNWYzFBak5aTGp5aGY4LXc", -5216118194371500773),
        ("MjI4OWU3MjQtNjhmZi00NDc2LTg1ODAtYmRhZTM5ZDMwZTk2Omt0TldDMjM4WVdWdTlOODd6d3pJaThjTnRDQmRHdW84M28zdXpYU2RRdlk", -9080853807181143023),
        ("MzVlNjNjMGEtMmY2MS00ZmFiLWJjMzItNDUxNjgxMDE1MjZlOkFQaUhtT0kxc1NxWWRMUWl1a0o0V2Q3TzZYcXo3VGxmNjdidVI2RzB3bW8", -5665330466168629790),
        ("MzVlNjNjMGEtMmY2MS00ZmFiLWJjMzItNDUxNjgxMDE1MjZlOlZ5RjVRdF9UUms3WHBlY2J1RE10aHI3LTdGLUVwT1hWS2doMVVVcEMxRGc", 3243549234120449130),
        ("MzVlNjNjMGEtMmY2MS00ZmFiLWJjMzItNDUxNjgxMDE1MjZlOlhxUndPMUlRNEpSUGppZFpzT1IxLW05MWFwTC1PY3VmOEhBT0F4M280NUE", -1585366410357579771),
        ("MzVlNjNjMGEtMmY2MS00ZmFiLWJjMzItNDUxNjgxMDE1MjZlOmFSb1V4MXBPYXBOZ0hwLU5sQU9fQU8tNERJdlJvUWJXVVdWX2ZXbmZ1c2s", 3714273504853941374),
        ("MzVlNjNjMGEtMmY2MS00ZmFiLWJjMzItNDUxNjgxMDE1MjZlOmVTMS1Sc2ZnTi1iWUtKeGJGWWF6T0ZUQXZKWndmaV9fV1A4R1h6S2pOVVE", 5594442463729557015),
        ("MzVlNjNjMGEtMmY2MS00ZmFiLWJjMzItNDUxNjgxMDE1MjZlOmc0UktsR216ZjIxSWdvY1FVNWJyQVp5SjNWb09LbnFkdW9TekVqVUZVUjg", 8661757951366205558),
        ("MzVlNjNjMGEtMmY2MS00ZmFiLWJjMzItNDUxNjgxMDE1MjZlOms2enFXZU96ckJHd0xBT1JBbkttZ21ELXFHUS03SDJ5Z1BBNG9MSlFHNEE", 8125713191749480222),
        ("NDg2MjgxZGQtYmJmMy00ZGYzLWIwZTAtNWY4NWZmOTUwNTQzOjBFNktzVW1aQmlhRG9jeDNSbWdiMTdoSndqY2YyZm5lcy1sTE0tUEl0SGM", 8098096393560598741),
        ("NDg2MjgxZGQtYmJmMy00ZGYzLWIwZTAtNWY4NWZmOTUwNTQzOjh1V2k4dEtNc04zOWZBNUJBbVd6dDJwMExsVUwyamFQWlNuMk5hbi03clU", -8381202611198822553),
        ("NDg2MjgxZGQtYmJmMy00ZGYzLWIwZTAtNWY4NWZmOTUwNTQzOkZHX2ZoXzgwTWludHhjSFFMb3B2Qm5BVHBGY3hURW8zelNTZTJPWXZxTlk", 8427434276397903294),
        ("NDg2MjgxZGQtYmJmMy00ZGYzLWIwZTAtNWY4NWZmOTUwNTQzOkhiRldsV1loYlVZNXJhdDI0NUdwLXU3YkNzYkRQdEo4RUh3UnZJQ00teGM", 7394570805030268357),
        ("NDg2MjgxZGQtYmJmMy00ZGYzLWIwZTAtNWY4NWZmOTUwNTQzOkhiSkVVaVpoSEdQNXhCSFEza2l6enVDRzN2QjgzVFctSHRJT3ZnZG1lSTA", 2798897743352337551),
        ("NDg2MjgxZGQtYmJmMy00ZGYzLWIwZTAtNWY4NWZmOTUwNTQzOnkxRlgyY0VlTDJZVUlFRFBiVVZZSk9yMWdzRVFBdG9oMFB1NS1BNVJEZjQ", 6682335455994725646),
    ]

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

    @Test(".hash on real refresh tokens matches the logged idempotency keys")
    func hashOnRealTokensMatchesLog() {
        for (token, oldKey) in Self.realRefreshTokens {
            #expect(token.hash == oldKey)
        }
    }

    @Test("Target produces distinct idempotency keys for all real refresh tokens")
    func targetProducesDistinctKeysForRealTokens() {
        let keys = Self.realRefreshTokens.compactMap { idempotencyKey(for: $0.token) }
        #expect(keys.count == Self.realRefreshTokens.count)
        #expect(Set(keys).count == keys.count)
    }

    private func idempotencyKey(for refreshToken: String) -> String? {
        let target = TangemPayAuthorizationAPITarget(
            target: .refreshTokens(request: .init(refreshToken: refreshToken)),
            apiType: .prod
        )
        return target.headers?["Idempotency-Key"]
    }
}
