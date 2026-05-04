//
//  ObjectAddressPreserveRuleTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct ObjectAddressPreserveRuleTests {
    @Test(arguments: RuleTestCases.Preserved.typicalObjectAddresses)
    func shouldPreserveTypicalObjectAddresses(testCase: PreserveLogTestCase) {
        let sut = Self.makeSUT()
        assert(preserved: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Preserved.edgeTypeNames)
    func shouldPreserveEdgeCaseTypeNames(testCase: PreserveLogTestCase) {
        let sut = Self.makeSUT()
        assert(preserved: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Preserved.edgeAddresses)
    func shouldPreserveEdgeCaseAddresses(testCase: PreserveLogTestCase) {
        let sut = Self.makeSUT()
        assert(preserved: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.invalidTypeNames)
    func shouldIgnoreInvalidTypeNames(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.invalidInstanceAddresses)
    func shouldIgnoreInvalidInstanceAddresses(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.nonObjectAddressStrings)
    func shouldIgnoreNonObjectAddressStrings(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }
}

// MARK: - Valid test cases

private extension RuleTestCases.Preserved {
    private static func placeholder(for index: UInt = 0) -> String {
        "__PRESERVE_RULE_OBJECT_ADDRESS_\(index)"
    }

    static let typicalObjectAddresses = [
        PreserveLogTestCase(
            originalLog: "<A: 0x12345678>",
            preservedLog: Self.placeholder(),
            capturedValues: ["<A: 0x12345678>"]
        ),
        PreserveLogTestCase(
            originalLog: "<_A: 0x12345678>",
            preservedLog: Self.placeholder(),
            capturedValues: ["<_A: 0x12345678>"]
        ),
        PreserveLogTestCase(
            originalLog: "<SomeClassName: 0x12345678>",
            preservedLog: Self.placeholder(),
            capturedValues: ["<SomeClassName: 0x12345678>"]
        ),
        PreserveLogTestCase(
            originalLog: "<SomeClassName: 0x1234567890ABCDEF>",
            preservedLog: Self.placeholder(),
            capturedValues: ["<SomeClassName: 0x1234567890ABCDEF>"]
        ),
        PreserveLogTestCase(
            originalLog: "<Some_Class_Name: 0x12345678>",
            preservedLog: Self.placeholder(),
            capturedValues: ["<Some_Class_Name: 0x12345678>"]
        ),
        PreserveLogTestCase(
            originalLog: "<SomeClass1: 0x12345678>",
            preservedLog: Self.placeholder(),
            capturedValues: ["<SomeClass1: 0x12345678>"]
        ),
        PreserveLogTestCase(
            originalLog: "<Foundation.URLSession: 0x12345678>",
            preservedLog: Self.placeholder(),
            capturedValues: ["<Foundation.URLSession: 0x12345678>"]
        ),
        PreserveLogTestCase(
            originalLog: "prefix <SomeClass: 0x12345678> suffix",
            preservedLog: "prefix \(Self.placeholder()) suffix",
            capturedValues: ["<SomeClass: 0x12345678>"]
        ),
        PreserveLogTestCase(
            originalLog: "first <A: 0x12345678> second <B: 0x87654321> third <Foundation.URLSession: 0x106f3a120>",
            preservedLog: "first \(Self.placeholder(for: 0)) "
                + "second \(Self.placeholder(for: 1)) "
                + "third \(Self.placeholder(for: 2))",
            capturedValues: [
                "<A: 0x12345678>",
                "<B: 0x87654321>",
                "<Foundation.URLSession: 0x106f3a120>",
            ]
        ),
        PreserveLogTestCase(
            originalLog: "response: <NSHTTPURLResponse: 0x106f3a120>",
            preservedLog: "response: \(Self.placeholder())",
            capturedValues: ["<NSHTTPURLResponse: 0x106f3a120>"]
        ),
    ]
}

// MARK: - Preserved edge type name cases

private extension RuleTestCases.Preserved {
    private static let dottedTypeName = PreserveLogTestCase(
        originalLog: "<A.B: 0x12345678>",
        preservedLog: Self.placeholder(),
        capturedValues: ["<A.B: 0x12345678>"]
    )

    private static let deeplyDottedTypeName = PreserveLogTestCase(
        originalLog: "<A.B.C: 0x12345678>",
        preservedLog: Self.placeholder(),
        capturedValues: ["<A.B.C: 0x12345678>"]
    )

    private static let typeNameWithConsecutiveUnderscores = PreserveLogTestCase(
        originalLog: "<A__B: 0x12345678>",
        preservedLog: Self.placeholder(),
        capturedValues: ["<A__B: 0x12345678>"]
    )

    private static let mangledSwiftUITypeNameInsideText = PreserveLogTestCase(
        originalLog: "NSLayoutConstraint warning for <_TtC7SwiftUI19SomePrivateView: 0x1234ABCD>",
        preservedLog: "NSLayoutConstraint warning for \(Self.placeholder())",
        capturedValues: ["<_TtC7SwiftUI19SomePrivateView: 0x1234ABCD>"]
    )

    private static let shortTypeNameWithTrailingDigit = PreserveLogTestCase(
        originalLog: "<A1: 0x12345678>",
        preservedLog: Self.placeholder(),
        capturedValues: ["<A1: 0x12345678>"]
    )

    private static let longTypeNameWithDigits = PreserveLogTestCase(
        originalLog: "<A1234567890: 0x12345678>",
        preservedLog: Self.placeholder(),
        capturedValues: ["<A1234567890: 0x12345678>"]
    )

    private static let objectAddressWrappedInParentheses = PreserveLogTestCase(
        originalLog: "wrapped(<SomeType: 0x12345678>)",
        preservedLog: "wrapped(\(Self.placeholder()))",
        capturedValues: ["<SomeType: 0x12345678>"]
    )

    private static let objectDescriptionWithShortUserInfo = PreserveLogTestCase(
        originalLog: "<CommonWalletModel: 0x106f3a120; name = Ethereum> Beep bop boop beep!",
        preservedLog: "\(Self.placeholder()) Beep bop boop beep!",
        capturedValues: ["<CommonWalletModel: 0x106f3a120; name = Ethereum>"]
    )

    private static let objectDescriptionWithLongUserInfo = PreserveLogTestCase(
        originalLog: "<CommonWalletModel: 0x106f3a120; name = Ethereum; isMainToken = true; tokenItem = Ethereum (Ethereum)> Updating state. New state is Loaded",
        preservedLog: "\(Self.placeholder()) Updating state. New state is Loaded",
        capturedValues: ["<CommonWalletModel: 0x106f3a120; name = Ethereum; isMainToken = true; tokenItem = Ethereum (Ethereum)>"]
    )

    private static let typeNameWithSingleDigitInsideUnderscores = PreserveLogTestCase(
        originalLog: "prefix <__1_: 0x12345678>",
        preservedLog: "prefix \(Self.placeholder())",
        capturedValues: ["<__1_: 0x12345678>"]
    )

    static let edgeTypeNames = [
        dottedTypeName,
        deeplyDottedTypeName,
        typeNameWithConsecutiveUnderscores,
        mangledSwiftUITypeNameInsideText,
        shortTypeNameWithTrailingDigit,
        longTypeNameWithDigits,
        objectAddressWrappedInParentheses,
        objectDescriptionWithShortUserInfo,
        objectDescriptionWithLongUserInfo,
        typeNameWithSingleDigitInsideUnderscores,
    ]
}

// MARK: - Preserved edge addresses

private extension RuleTestCases.Preserved {
    private static let uppercaseHexAddress = PreserveLogTestCase(
        originalLog: "<SomeType: 0xABCDEF12>",
        preservedLog: Self.placeholder(),
        capturedValues: ["<SomeType: 0xABCDEF12>"]
    )

    private static let lowercaseHexAddress = PreserveLogTestCase(
        originalLog: "<SomeType: 0xabcdef12>",
        preservedLog: Self.placeholder(),
        capturedValues: ["<SomeType: 0xabcdef12>"]
    )

    private static let maximumLengthHexAddress = PreserveLogTestCase(
        originalLog: "<SomeType: 0x123456789abcdef0>",
        preservedLog: Self.placeholder(),
        capturedValues: ["<SomeType: 0x123456789abcdef0>"]
    )

    static let edgeAddresses = [
        uppercaseHexAddress,
        lowercaseHexAddress,
        maximumLengthHexAddress,
    ]
}

// MARK: - Ignored type name cases

private extension RuleTestCases.Ignored {
    private static let singleUnderscore = "<_: 0x12345678>"
    private static let multipleUnderscoreWithoutLetterOrDigit = "<___: 0x12345678>"
    private static let startsWithDigit = "<1Class: 0x12345678>"
    private static let startsWithDot = "<.Class: 0x12345678>"
    private static let endsWithDot = "<Class.: 0x12345678>"
    private static let repeatedTrailingDots = "<Class..: 0x12345678>"
    private static let containsHyphen = "<Some-Class: 0x12345678>"
    private static let containsSpace = "<Some Class: 0x12345678>"
    private static let containsSlash = "<Some/Class: 0x12345678>"
    private static let containsExclamation = "<SomeClass!: 0x12345678>"
    private static let containsQuestion = "<SomeClass?: 0x12345678>"
    private static let emptyTypeName = "<: 0x12345678>"

    static let invalidTypeNames = [
        singleUnderscore,
        multipleUnderscoreWithoutLetterOrDigit,
        startsWithDigit,
        startsWithDot,
        endsWithDot,
        repeatedTrailingDots,
        containsHyphen,
        containsSpace,
        containsSlash,
        containsExclamation,
        containsQuestion,
        emptyTypeName,
    ]
}

// MARK: - Ignored instance address cases

private extension RuleTestCases.Ignored {
    private static let tooShortHex = "<SomeClass: 0x1234567>"
    private static let tooLongHex = "<SomeClass: 0x1234567890ABCDEF0>"
    private static let tooLongHexWithUserInfo = "<CommonWalletModel: 0x1234567890ABCDEF0; name = Ethereum>"
    private static let missingHexPrefix = "<SomeClass: 12345678>"
    private static let uppercaseHexPrefix = "<SomeClass: 0X12345678>"
    private static let missingHexValue = "<SomeClass: 0x>"
    private static let containsNonHexUppercaseLetter = "<SomeClass: 0x1234567G>"
    private static let containsNonHexLowercaseLetter = "<SomeClass: 0x1234567g>"
    private static let containsOnlyNonHexLetters = "<SomeClass: 0xYYYYYYYYY>"
    private static let containsWhitespaceInsideHex = "<SomeClass: 0x1234 5678>"
    private static let containsHyphenInsideHex = "<SomeClass: 0x1234-5678>"

    static let invalidInstanceAddresses = [
        tooShortHex,
        tooLongHex,
        tooLongHexWithUserInfo,
        missingHexPrefix,
        uppercaseHexPrefix,
        missingHexValue,
        containsNonHexUppercaseLetter,
        containsNonHexLowercaseLetter,
        containsOnlyNonHexLetters,
        containsWhitespaceInsideHex,
        containsHyphenInsideHex,
    ]
}

// MARK: - Other ignored string cases

private extension RuleTestCases.Ignored {
    private static let plainTypeAndAddress = "SomeClass: 0x12345678"
    private static let missingOpeningBracket = "SomeClass: 0x12345678>"
    private static let missingClosingBracket = "<SomeClass: 0x12345678"
    private static let missingColonSpace = "<SomeClass:0x12345678>"
    private static let extraWhitespaceAfterColon = "<SomeClass:  0x12345678>"
    private static let whitespaceBeforeColon = "<SomeClass : 0x12345678>"
    private static let randomText = "object address somewhere maybe"
    private static let hexOnly = "0x12345678"
    private static let typeOnly = "<SomeClass>"
    private static let emptyString = ""

    static let nonObjectAddressStrings = [
        plainTypeAndAddress,
        missingOpeningBracket,
        missingClosingBracket,
        missingColonSpace,
        extraWhitespaceAfterColon,
        whitespaceBeforeColon,
        randomText,
        hexOnly,
        typeOnly,
        emptyString,
    ]
}

extension ObjectAddressPreserveRuleTests {
    private static func makeSUT() -> PreserveRule {
        PreserveRule.objectAddress
    }
}
