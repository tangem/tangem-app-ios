//
//  SensitiveKeyRedactRuleTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct SensitiveKeyRedactRuleTests {
    @Test(arguments: RuleTestCases.Redacted.sensitiveKeys)
    func shouldRedactSensitiveKeys(testCase: RedactLogTestCase) {
        let sut = Self.makeSUT()
        assert(redacted: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Redacted.edgeSensitiveKeys)
    func shouldRedactEdgeCaseSensitiveKeys(testCase: RedactLogTestCase) {
        let sut = Self.makeSUT()
        assert(redacted: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.alreadyRedactedSensitiveKeys)
    func shouldIgnoreAlreadyRedactedSensitiveKeys(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.nonSensitiveKeys)
    func shouldIgnoreNonSensitiveKeys(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }
}

// MARK: - Redacted test cases

private extension RuleTestCases.Redacted {
    private static let placeholder = "REDACTED_SENSITIVE_KEY"

    private static let apiKeyWithEquals = RedactLogTestCase(
        originalLog: "api-key=secret123",
        redactedLog: "api-key=\(Self.placeholder)"
    )

    private static let apiKeyWithColonAndQuotes = RedactLogTestCase(
        originalLog: #""api-key": "secret123""#,
        redactedLog: #""api-key": "\#(Self.placeholder)""#
    )

    private static let xApiKeyHeader = RedactLogTestCase(
        originalLog: #""x-api-key": "secret123""#,
        redactedLog: #""x-api-key": "\#(Self.placeholder)""#
    )

    private static let apiKeyUnderscore = RedactLogTestCase(
        originalLog: "api_key=secret123",
        redactedLog: "api_key=\(Self.placeholder)"
    )

    private static let apiKeyCompact = RedactLogTestCase(
        originalLog: "apikey=secret123",
        redactedLog: "apikey=\(Self.placeholder)"
    )

    private static let accessTokenAsOneWord = RedactLogTestCase(
        originalLog: "accesstoken: token123",
        redactedLog: "accesstoken: \(Self.placeholder)"
    )

    private static let accessTokenDash = RedactLogTestCase(
        originalLog: "access-token: token123",
        redactedLog: "access-token: \(Self.placeholder)"
    )

    private static let accessTokenUnderscore = RedactLogTestCase(
        originalLog: "access_token=token123",
        redactedLog: "access_token=\(Self.placeholder)"
    )

    private static let authKey = RedactLogTestCase(
        originalLog: "auth: my_token",
        redactedLog: "auth: \(Self.placeholder)"
    )

    private static let genericKey = RedactLogTestCase(
        originalLog: "key=value123",
        redactedLog: "key=\(Self.placeholder)"
    )

    private static let multipleSensitiveKeys = RedactLogTestCase(
        originalLog: #"api-key=secret123 access-token=abc123 auth: xyz777"#,
        redactedLog: #"api-key=\#(Self.placeholder) access-token=\#(Self.placeholder) auth: \#(Self.placeholder)"#
    )

    static let sensitiveKeys = [
        apiKeyWithEquals,
        apiKeyWithColonAndQuotes,
        xApiKeyHeader,
        apiKeyUnderscore,
        apiKeyCompact,
        accessTokenAsOneWord,
        accessTokenDash,
        accessTokenUnderscore,
        authKey,
        genericKey,
        multipleSensitiveKeys,
    ]
}

// MARK: - Redacted edge test cases

private extension RuleTestCases.Redacted {
    private static let uppercaseKeyName = RedactLogTestCase(
        originalLog: "API-KEY=secret123",
        redactedLog: "API-KEY=\(Self.placeholder)"
    )

    private static let noWhitespaceAroundSeparator = RedactLogTestCase(
        originalLog: #""api-key":"secret123""#,
        redactedLog: #""api-key":"\#(Self.placeholder)""#
    )

    private static let excessiveWhitespaceAroundSeparator = RedactLogTestCase(
        originalLog: #"api-key    :    "secret123""#,
        redactedLog: #"api-key    :    "\#(Self.placeholder)""#
    )

    private static let valueWithDotsUnderscoresAndHyphens = RedactLogTestCase(
        originalLog: "api-key=abc.DEF_123-xyz",
        redactedLog: "api-key=\(Self.placeholder)"
    )

    private static let keyEmbeddedInLongerText = RedactLogTestCase(
        originalLog: #"request headers: ["api-key": "secret123"] for call"#,
        redactedLog: #"request headers: ["api-key": "\#(Self.placeholder)"] for call"#
    )

    private static let twoQuotedKeysInOneLine = RedactLogTestCase(
        originalLog: #""api-key": "secret123", "x-api-key": "secret456""#,
        redactedLog: #""api-key": "\#(Self.placeholder)", "x-api-key": "\#(Self.placeholder)""#
    )

    static let edgeSensitiveKeys = [
        uppercaseKeyName,
        noWhitespaceAroundSeparator,
        excessiveWhitespaceAroundSeparator,
        valueWithDotsUnderscoresAndHyphens,
        keyEmbeddedInLongerText,
        twoQuotedKeysInOneLine,
    ]
}

// MARK: - Ignored already redacted test cases

private extension RuleTestCases.Ignored {
    private static let placeholder = "REDACTED_SENSITIVE_KEY"

    private static let alreadyRedactedApiKeyEquals = "api-key=\(Self.placeholder)"
    private static let alreadyRedactedApiKeyColon = #"api-key: "\#(Self.placeholder)""#
    private static let alreadyRedactedQuotedKey = #""api-key": "\#(Self.placeholder)""#
    private static let alreadyRedactedMultipleKeys = #"api-key=\#(Self.placeholder) token=\#(Self.placeholder)"#

    static let alreadyRedactedSensitiveKeys = [
        alreadyRedactedApiKeyEquals,
        alreadyRedactedApiKeyColon,
        alreadyRedactedQuotedKey,
        alreadyRedactedMultipleKeys,
    ]
}

// MARK: - Other ignored string cases

private extension RuleTestCases.Ignored {
    static let unrelatedHeader = "content-type=application/json"
    static let normalSentence = "this log line has no sensitive key"
    static let unrecognizedExtendedKeyName = "api-key-extra=secret123"
    static let valueWithoutExplicitSeparator = "token expired"
    static let emptyString = ""
    static let randomJson = #"{"name":"visa-waitlist"}"#
    static let analyticsEventWithTokenWord = """
    Analytics event: [Token / Send] Send With Swap Confirm Screen Opened.
    Params: {
    "Batch":"GG42"
    "Currency": "Multicurrency",
    "Firmware": "1.337",
    "Product Type": "Wallet 5.0",
    "Provider": "BestProvider01",
    "Rate Type": "Float",
    "Receive Blockchain": "Ethereum",
    "Receive Token": "USDC",
    "Send Blockchain": "Ethereum",
    "Send Token": "USDT"
    }
    """

    static let nonSensitiveKeys = [
        unrelatedHeader,
        normalSentence,
        unrecognizedExtendedKeyName,
        valueWithoutExplicitSeparator,
        emptyString,
        randomJson,
        analyticsEventWithTokenWord,
    ]
}

extension SensitiveKeyRedactRuleTests {
    private static func makeSUT() -> RedactRule {
        RedactRule.sensitiveKey
    }
}
