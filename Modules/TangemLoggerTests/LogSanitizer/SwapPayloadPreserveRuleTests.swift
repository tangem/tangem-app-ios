//
//  SwapPayloadPreserveRuleTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct SwapPayloadPreserveRuleTests {
    @Test(arguments: RuleTestCases.Preserved.swapPayload)
    func shouldPreserveSwapPayloadKeysWithHexValues(testCase: PreserveLogTestCase) {
        let sut = Self.makeSUT()
        assert(preserved: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.swapPayload)
    func shouldIgnoreSwapPayload(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }
}

// MARK: - Preserved test cases

private extension RuleTestCases.Preserved {
    private static func placeholder(for index: UInt = 0) -> String {
        "__PRESERVE_RULE_SWAP_PAYLOAD_\(index)"
    }

    static let txId = PreserveLogTestCase(
        originalLog: #""txId":"23b0ba60-8f61-4917-83e7-0464f97f1d55""#,
        preservedLog: Self.placeholder(),
        capturedValues: [#""txId":"23b0ba60-8f61-4917-83e7-0464f97f1d55""#]
    )

    static let txHash = PreserveLogTestCase(
        originalLog: #""txHash": "0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d""#,
        preservedLog: Self.placeholder(),
        capturedValues: [#""txHash": "0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d""#]
    )

    static let fromAddress = PreserveLogTestCase(
        originalLog: #""fromAddress":"0x0f0632254b1b45b835e5911E729871667E91BE12""#,
        preservedLog: Self.placeholder(),
        capturedValues: [#""fromAddress":"0x0f0632254b1b45b835e5911E729871667E91BE12""#]
    )

    static let fromAddressWithExtraWhitespaces = PreserveLogTestCase(
        originalLog: #""fromAddress"   :   "0x0f0632254b1b45b835e5911E729871667E91BE12""#,
        preservedLog: Self.placeholder(),
        capturedValues: [#""fromAddress"   :   "0x0f0632254b1b45b835e5911E729871667E91BE12""#]
    )

    static let refundAddressWithPrefixAndSuffix = PreserveLogTestCase(
        originalLog: #"prefix "refundAddress": "0x89f423567c2648BB828c3997f60c47b54f57Fa6e" suffix"#,
        preservedLog: #"prefix \#(Self.placeholder()) suffix"#,
        capturedValues: [#""refundAddress": "0x89f423567c2648BB828c3997f60c47b54f57Fa6e""#]
    )

    static let multipleValues = PreserveLogTestCase(
        originalLog: #""txId":"23b0ba60-8f61-4917-83e7-0464f97f1d55","fromAddress":"0x1","txHash":"0x2""#,
        preservedLog: #"\#(Self.placeholder(for: 0)),\#(Self.placeholder(for: 1)),\#(Self.placeholder(for: 2))"#,
        capturedValues: [
            #""txId":"23b0ba60-8f61-4917-83e7-0464f97f1d55""#,
            #""fromAddress":"0x1""#,
            #""txHash":"0x2""#,
        ]
    )

    static let swapPayload = [
        RuleTestCases.Preserved.txId,
        RuleTestCases.Preserved.txHash,
        RuleTestCases.Preserved.fromAddress,
        RuleTestCases.Preserved.fromAddressWithExtraWhitespaces,
        RuleTestCases.Preserved.refundAddressWithPrefixAndSuffix,
        RuleTestCases.Preserved.multipleValues,
    ]
}

// MARK: - Ignored test cases

private extension RuleTestCases.Ignored {
    static let providerId = #""providerId": "okx-cross-chain""#
    static let status = #""status": "finished""#
    static let fromNetwork = #""fromNetwork": "polygon-pos""#
    static let fromAmount = #""fromAmount": "9000000""#
    static let fromDecimals = #""fromDecimals": 6"#
    static let unknownField = #""unknownField": "0x0f0632254b1b45b835e5911E729871667E91BE12""#
    static let missingOpeningQuote = #""fromAddress": 0x0f0632254b1b45b835e5911E729871667E91BE12"#
    static let missingClosingQuote = #""fromAddress": "0xabc"#
    static let newline = #"""
      "fromAddress" :
      "0xabc""
    """#

    static let swapPayload = [
        RuleTestCases.Ignored.providerId,
        RuleTestCases.Ignored.status,
        RuleTestCases.Ignored.fromNetwork,
        RuleTestCases.Ignored.fromAmount,
        RuleTestCases.Ignored.fromDecimals,
        RuleTestCases.Ignored.unknownField,
        RuleTestCases.Ignored.missingOpeningQuote,
        RuleTestCases.Ignored.missingClosingQuote,
        RuleTestCases.Ignored.newline,
    ]
}

private extension SwapPayloadPreserveRuleTests {
    static func makeSUT() -> PreserveRule {
        PreserveRule.swapPayload
    }
}
