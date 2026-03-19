//
//  UnarchivedCryptoAccountNameIndexerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("UnarchivedCryptoAccountNameIndexer Tests")
struct UnarchivedCryptoAccountNameIndexerTests {
    @Test("Makes account name with initial index when no existing suffix")
    func makeAccountNameWithInitialIndex() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "Bitcoin")
        #expect(result == "Bitcoin(1)")
    }

    @Test("Increments index when existing suffix found")
    func incrementsExistingIndex() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "Bitcoin(5)")
        #expect(result == "Bitcoin(6)")
    }

    @Test("Handles multi-digit indices")
    func handlesMultiDigitIndices() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "Ethereum(123)")
        #expect(result == "Ethereum(124)")
    }

    @Test("Handles edge case with zero index")
    func handlesZeroIndex() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "Account(0)")
        #expect(result == "Account(1)")
    }

    @Test("Ignores parentheses not at end of string #1")
    func ignoresParenthesesNotAtEnd1() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "Bitcoin(old)new")
        #expect(result == "Bitcoin(old)new(1)")
    }

    @Test("Ignores parentheses not at end of string #2")
    func ignoresParenthesesNotAtEnd2() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "Bitcoin(10)new")
        #expect(result == "Bitcoin(10)new(1)")
    }

    @Test("Handles empty string input")
    func handlesEmptyString() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "")
        #expect(result == "(1)")
    }

    @Test("Handles string with only parentheses and number")
    func handlesOnlyParenthesesAndNumber() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "(42)")
        #expect(result == "(43)")
    }

    @Test("Handles very large numbers")
    func handlesVeryLargeNumbers() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "Account(999999)")
        #expect(result == "Account(1000000)")
    }

    @Test("Handles single digit numbers")
    func handlesSingleDigitNumbers() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "Wallet(9)")
        #expect(result == "Wallet(10)")
    }

    @Test("Handles names with spaces before parentheses")
    func handlesSpacesBeforeParentheses() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "My Account (5)")
        #expect(result == "My Account (6)")
    }

    @Test("Handles Unicode characters in account names")
    func handlesUnicodeCharacters() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "Bitcoin💰(2)")
        #expect(result == "Bitcoin💰(3)")
    }

    @Test("Ignores malformed suffix patterns")
    func ignoresMalformedSuffixes() {
        let testCases = [
            "Bitcoin(abc)": "Bitcoin(abc)(1)",
            "Bitcoin()": "Bitcoin()(1)",
            "Bitcoin(": "Bitcoin((1)",
            "Bitcoin)": "Bitcoin)(1)",
        ]

        for (input, expected) in testCases {
            let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: input)
            #expect(result == expected, "Failed for input: \(input)")
        }
    }

    @Test("Properly truncates input")
    func truncatesInput() {
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: "EthereumEthereumEthereum(999)")
        #expect(result == "EthereumEthere(1000)")
    }

    @Test("Respects maximum account name length constraint")
    func respectsMaximumLength() {
        let longName = String(repeating: "a", count: 100)
        let result = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: longName)

        // The result should end with "(1)" and not exceed the maximum length
        #expect(result.hasSuffix("(1)"))
        #expect(result.count <= AccountModelUtils.maxAccountNameLength)
    }
}
