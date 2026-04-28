//
//  IdempotencyKeyPreserveRuleTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct IdempotencyKeyPreserveRuleTests {
    @Test(arguments: RuleTestCases.Preserved.idempotencyKey)
    func shouldPreserveIdempotencyKeyHex(testCase: PreserveLogTestCase) {
        let sut = Self.makeSUT()
        assert(preserved: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.idempotencyKey)
    func shouldIgnoreNonMatching(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }

    private static func makeSUT() -> PreserveRule {
        PreserveRule.idempotencyKey
    }
}

// MARK: - Preserved test cases

private extension RuleTestCases.Preserved {
    private static func placeholder(for index: UInt = 0) -> String {
        "__PRESERVE_RULE_IDEMPOTENCY_KEY_\(index)"
    }

    static let basic = PreserveLogTestCase(
        originalLog: "Idempotency-Key-New: 14cc15f0e2f5986f28a7b35525183b6c45446cdf8ec84aeb9113fc2d6bae1ca0",
        preservedLog: Self.placeholder(),
        capturedValues: ["Idempotency-Key-New: 14cc15f0e2f5986f28a7b35525183b6c45446cdf8ec84aeb9113fc2d6bae1ca0"]
    )

    static let withSurroundingText = PreserveLogTestCase(
        originalLog: "refreshToken: ABC, Idempotency-Key-Old: 12345, Idempotency-Key-New: 14cc15f0e2f5986f28a7b35525183b6c45446cdf8ec84aeb9113fc2d6bae1ca0",
        preservedLog: "refreshToken: ABC, Idempotency-Key-Old: 12345, \(Self.placeholder())",
        capturedValues: ["Idempotency-Key-New: 14cc15f0e2f5986f28a7b35525183b6c45446cdf8ec84aeb9113fc2d6bae1ca0"]
    )

    static let idempotencyKey = [
        RuleTestCases.Preserved.basic,
        RuleTestCases.Preserved.withSurroundingText,
    ]
}

// MARK: - Ignored test cases

private extension RuleTestCases.Ignored {
    static let idempotencyKey = [
        // No prefix label
        "14cc15f0e2f5986f28a7b35525183b6c45446cdf8ec84aeb9113fc2d6bae1ca0",
        // Wrong label (Old, not New)
        "Idempotency-Key-Old: 14cc15f0e2f5986f28a7b35525183b6c45446cdf8ec84aeb9113fc2d6bae1ca0",
        // Hex too short (only 32 chars)
        "Idempotency-Key-New: 14cc15f0e2f5986f28a7b35525183b6c",
        // Non-hex characters in the value
        "Idempotency-Key-New: 14cc15f0e2f5986f28a7b35525183b6c45446cdf8ec84aeb9113fc2d6bae1cZZ",
    ]
}
