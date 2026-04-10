//
//  ISO8601TimestampPreserveRuleTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct ISO8601TimestampPreserveRuleTests {
    @Test(arguments: RuleTestCases.Preserved.timestamps)
    func shouldPreserveValidTimestamps(testCase: PreserveLogTestCase) {
        let sut = Self.makeSUT()
        assert(preserved: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.dateComponents)
    func shouldIgnoreInvalidDateComponents(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.timeComponents)
    func shouldIgnoreInvalidTimeComponents(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.nonTimestampStrings)
    func shouldIgnoreNonTimestampStrings(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }
}

// MARK: - Preserved test cases

private extension RuleTestCases.Preserved {
    private static func placeholder(for index: UInt = 0) -> String {
        "__PRESERVE_RULE_ISO8601_TIMESTAMP_\(index)"
    }

    static let timestamps = [
        PreserveLogTestCase(
            originalLog: "2026-12-24T00:00:00Z",
            preservedLog: Self.placeholder(),
            capturedValues: ["2026-12-24T00:00:00Z"]
        ),
        PreserveLogTestCase(
            originalLog: "2026-12-24T00:00:00.000Z",
            preservedLog: Self.placeholder(),
            capturedValues: ["2026-12-24T00:00:00.000Z"]
        ),
        PreserveLogTestCase(
            originalLog: "1970-01-01T00:00:00Z",
            preservedLog: Self.placeholder(),
            capturedValues: ["1970-01-01T00:00:00Z"]
        ),
        PreserveLogTestCase(
            originalLog: #"{"start":"2026-12-24T00:00:00.000Z"}"#,
            preservedLog: #"{"start":"\#(Self.placeholder())"}"#,
            capturedValues: ["2026-12-24T00:00:00.000Z"]
        ),
        PreserveLogTestCase(
            originalLog: #"{"start":"2026-12-24T00:00:00.000Z","end":"1970-01-01T12:34:56Z"}"#,
            preservedLog: #"{"start":"\#(Self.placeholder(for: 0))","end":"\#(Self.placeholder(for: 1))"}"#,
            capturedValues: [
                "2026-12-24T00:00:00.000Z",
                "1970-01-01T12:34:56Z",
            ]
        ),
    ]
}

// MARK: - Ignored date component cases

private extension RuleTestCases.Ignored {
    private static let dateOnly = "2026-12-24"
    private static let missingMonth = "2026--24T00:00:00Z"
    private static let missingDay = "2026-12-T00:00:00Z"
    private static let shortMonth = "2026-1-24T00:00:00Z"
    private static let shortDay = "2026-12-4T00:00:00Z"
    private static let shortYear = "026-12-24T00:00:00Z"
    private static let slashSeparatedDate = "2026/12/24T00:00:00Z"
    private static let dotSeparatedDate = "2026.12.24T00:00:00Z"
    private static let zeroMonth = "2025-00-24T00:00:00Z"
    private static let impossibleMonth = "2025-13-24T00:00:00Z"
    private static let zeroDay = "2025-12-00T00:00:00Z"
    private static let impossibleDay = "2025-12-32T00:00:00Z"

    static let dateComponents = [
        dateOnly,
        missingMonth,
        missingDay,
        shortMonth,
        shortDay,
        shortYear,
        slashSeparatedDate,
        dotSeparatedDate,
        zeroMonth,
        impossibleMonth,
        zeroDay,
        impossibleDay,
    ]
}

// MARK: - Ignored time component cases

private extension RuleTestCases.Ignored {
    private static let missingZuluSuffix = "2025-12-24T00:00:00"
    private static let missingTSeparator = "2025-12-24 00:00:00Z"
    private static let missingSeconds = "2025-12-24T00:00Z"
    private static let missingFractionDigits = "2025-12-24T00:00:00.Z"
    private static let lowercaseZuluSuffix = "2025-12-24T00:00:00z"
    private static let impossibleHour = "2025-12-24T24:00:00Z"
    private static let impossibleMinute = "2025-12-24T00:60:00Z"
    private static let impossibleSecond = "2025-12-24T00:00:60Z"

    static let timeComponents = [
        missingZuluSuffix,
        missingTSeparator,
        missingSeconds,
        missingFractionDigits,
        lowercaseZuluSuffix,
        impossibleHour,
        impossibleMinute,
        impossibleSecond,
    ]
}

// MARK: - Other ignored string cases

private extension RuleTestCases.Ignored {
    static let nonTimestampStrings = [
        "",
        "timestamp",
        "REDACTEDT00:00:00.000Z",
        "2025/12/24T00:00:00Z",
        "24-12-2025T00:00:00Z",
    ]
}

extension ISO8601TimestampPreserveRuleTests {
    private static func makeSUT() -> PreserveRule {
        PreserveRule.iso8601Timestamp
    }
}
