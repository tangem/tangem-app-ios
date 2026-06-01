//
//  TokenContractAddressPreserveRuleTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct TokenContractAddressPreserveRuleTests {
    @Test(arguments: RuleTestCases.Preserved.tokenContractAddress)
    func shouldPreserveTokenContractAddressValues(testCase: PreserveLogTestCase) {
        let sut = Self.makeSUT()
        assert(preserved: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.tokenContractAddress)
    func shouldIgnoreNonMatchingFragments(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }
}

// MARK: - Preserved test cases

private extension RuleTestCases.Preserved {
    private static func placeholder(for index: UInt = 0) -> String {
        "__PRESERVE_RULE_TOKEN_CONTRACT_ADDRESS_\(index)"
    }

    static let evmContractAddress = PreserveLogTestCase(
        originalLog: #""contractAddress":"0xaf88d065e77c8cc2239327c5edb3a432268e5831""#,
        preservedLog: Self.placeholder(),
        capturedValues: [#""contractAddress":"0xaf88d065e77c8cc2239327c5edb3a432268e5831""#]
    )

    static let evmContractAddressWithExtraWhitespaces = PreserveLogTestCase(
        originalLog: #""contractAddress"   :   "0xdac17f958d2ee523a2206206994597c13d831ec7""#,
        preservedLog: Self.placeholder(),
        capturedValues: [#""contractAddress"   :   "0xdac17f958d2ee523a2206206994597c13d831ec7""#]
    )

    static let evmContractAddressWithPrefixAndSuffix = PreserveLogTestCase(
        originalLog: #"prefix "contractAddress":"0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48" suffix"#,
        preservedLog: #"prefix \#(Self.placeholder()) suffix"#,
        capturedValues: [#""contractAddress":"0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48""#]
    )

    static let stellarAssetContractAddress = PreserveLogTestCase(
        originalLog: #""contractAddress":"USDC-GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN""#,
        preservedLog: Self.placeholder(),
        capturedValues: [#""contractAddress":"USDC-GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN""#]
    )

    static let xrpIssuedCurrencyContractAddress = PreserveLogTestCase(
        originalLog: #""contractAddress":"4245415200000000000000000000000000000000.rBEARGUAsyu7tUw53rufQzFdWmJHpJEqFW""#,
        preservedLog: Self.placeholder(),
        capturedValues: [#""contractAddress":"4245415200000000000000000000000000000000.rBEARGUAsyu7tUw53rufQzFdWmJHpJEqFW""#]
    )

    static let emptyContractAddress = PreserveLogTestCase(
        originalLog: #""contractAddress":"""#,
        preservedLog: Self.placeholder(),
        capturedValues: [#""contractAddress":"""#]
    )

    static let multipleContractAddresses = PreserveLogTestCase(
        originalLog: #""contractAddress":"0xaf88","networkId":"avalanche","contractAddress":"0xdac17""#,
        preservedLog: #"\#(Self.placeholder(for: 0)),"networkId":"avalanche",\#(Self.placeholder(for: 1))"#,
        capturedValues: [
            #""contractAddress":"0xaf88""#,
            #""contractAddress":"0xdac17""#,
        ]
    )

    static let tokenContractAddress = [
        RuleTestCases.Preserved.evmContractAddress,
        RuleTestCases.Preserved.evmContractAddressWithExtraWhitespaces,
        RuleTestCases.Preserved.evmContractAddressWithPrefixAndSuffix,
        RuleTestCases.Preserved.stellarAssetContractAddress,
        RuleTestCases.Preserved.xrpIssuedCurrencyContractAddress,
        RuleTestCases.Preserved.emptyContractAddress,
        RuleTestCases.Preserved.multipleContractAddresses,
    ]
}

// MARK: - Ignored test cases

private extension RuleTestCases.Ignored {
    static let fromContractAddressBelongsToSwapRule = #""fromContractAddress":"0xaf88d065e77c8cc2239327c5edb3a432268e5831""#
    static let toContractAddressBelongsToSwapRule = #""toContractAddress":"0xaf88d065e77c8cc2239327c5edb3a432268e5831""#
    static let differentField = #""networkId":"avalanche""#
    static let nullValue = #""contractAddress":null"#
    static let missingOpeningQuote = #""contractAddress": 0xaf88d065e77c8cc2239327c5edb3a432268e5831"#
    static let missingClosingQuote = #""contractAddress": "0xaf88"#
    static let valueOnNextLine = #"""
      "contractAddress" :
      "0xaf88""
    """#

    static let tokenContractAddress = [
        RuleTestCases.Ignored.fromContractAddressBelongsToSwapRule,
        RuleTestCases.Ignored.toContractAddressBelongsToSwapRule,
        RuleTestCases.Ignored.differentField,
        RuleTestCases.Ignored.nullValue,
        RuleTestCases.Ignored.missingOpeningQuote,
        RuleTestCases.Ignored.missingClosingQuote,
        RuleTestCases.Ignored.valueOnNextLine,
    ]
}

private extension TokenContractAddressPreserveRuleTests {
    static func makeSUT() -> PreserveRule {
        PreserveRule.tokenContractAddress
    }
}
