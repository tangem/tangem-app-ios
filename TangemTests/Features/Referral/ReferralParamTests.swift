//
//  ReferralParamTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Referral parameter validation")
struct ReferralParamTests {
    @Test("Blank and null-like values are discarded", arguments: [nil, "", " ", "\n", "null"] as [String?])
    func invalidValues(rawValue: String?) {
        #expect(ReferralParam.normalized(rawValue) == nil)
    }

    @Test("A meaningful value is kept and trimmed", arguments: [
        ("REF1", "REF1"),
        (" REF1 ", "REF1"),
        ("nullish", "nullish"),
    ])
    func validValues(rawValue: String, expected: String) {
        #expect(ReferralParam.normalized(rawValue) == expected)
    }
}
