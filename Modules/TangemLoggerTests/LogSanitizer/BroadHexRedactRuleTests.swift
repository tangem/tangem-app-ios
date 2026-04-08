//
//  BroadHexRedactRuleTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct BroadHexRedactRuleTests {
    @Test(arguments: RuleTestCases.Redacted.hexValues)
    func shouldRedactHexValues(testCase: RedactLogTestCase) {
        let sut = Self.makeSUT()
        assert(redacted: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Redacted.knownBroadRedactions)
    func knownBroadRedactions(testCase: RedactLogTestCase) {
        let sut = Self.makeSUT()
        assert(redacted: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.nonHexValues)
    func shouldIgnoreNonHexValues(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }
}

// MARK: - Redacted cases

private extension RuleTestCases.Redacted {
    private static let placeholder = "REDACTED_HEX"

    private static let lowercaseHex = RedactLogTestCase(
        originalLog: "deadbeef",
        redactedLog: Self.placeholder
    )

    private static let uppercaseHex = RedactLogTestCase(
        originalLog: "DEADBEEF",
        redactedLog: Self.placeholder
    )

    private static let mixedCaseHex = RedactLogTestCase(
        originalLog: "DeAdBeEf",
        redactedLog: Self.placeholder
    )

    private static let prefixedLowercaseHex = RedactLogTestCase(
        originalLog: "0xdeadbeef",
        redactedLog: Self.placeholder
    )

    private static let prefixedUppercaseHex = RedactLogTestCase(
        originalLog: "0XDEADBEEF",
        redactedLog: Self.placeholder
    )

    private static let hyphenSeparatedHex = RedactLogTestCase(
        originalLog: "de-ad-be-ef",
        redactedLog: Self.placeholder
    )

    private static let longHexInsideText = RedactLogTestCase(
        originalLog: "prefix deadbeef suffix",
        redactedLog: "prefix \(Self.placeholder) suffix"
    )

    private static let prefixedHexInsideText = RedactLogTestCase(
        originalLog: "value=0xdeadbeef",
        redactedLog: "value=\(Self.placeholder)"
    )

    private static let multipleHexValues = RedactLogTestCase(
        originalLog: "deadbeef and cafe1234",
        redactedLog: "\(Self.placeholder) and \(Self.placeholder)"
    )

    static let hexValues = [
        lowercaseHex,
        uppercaseHex,
        mixedCaseHex,
        prefixedLowercaseHex,
        prefixedUppercaseHex,
        hyphenSeparatedHex,
        longHexInsideText,
        prefixedHexInsideText,
        multipleHexValues,
    ]
}

// MARK: - Known broad redaction cases

private extension RuleTestCases.Redacted {
    private static let iso8601DatePrefix = RedactLogTestCase(
        originalLog: "2025-12-24T00:00:00.000Z",
        redactedLog: "\(Self.placeholder)T00:00:00.000Z"
    )

    private static let objectAddressBody = RedactLogTestCase(
        originalLog: "<SomeClass: 0x12345678>",
        redactedLog: "<SomeClass: \(Self.placeholder)>"
    )

    static let knownBroadRedactions = [
        iso8601DatePrefix,
        objectAddressBody,
    ]
}

// MARK: - Ignored non-hex cases

private extension RuleTestCases.Ignored {
    private static let tooShortHex = "abc123"
    private static let nonHexLetters = "xyzxyzxyz"
    private static let shortPrefixedHex = "0x123456"
    private static let plainText = "normal text"
    private static let emptyString = ""
    private static let decimalNumber = "12345678"
    private static let uuidLikeButNotHex = "zz-zz-zz-zz"

    static let nonHexValues = [
        tooShortHex,
        nonHexLetters,
        shortPrefixedHex,
        plainText,
        emptyString,
        decimalNumber,
        uuidLikeButNotHex,
    ]
}

extension BroadHexRedactRuleTests {
    private static func makeSUT() -> RedactRule {
        RedactRule.broadHex
    }
}
