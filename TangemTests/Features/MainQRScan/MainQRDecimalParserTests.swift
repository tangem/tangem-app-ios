//
//  MainQRDecimalParserTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MainQRDecimalParser")
struct MainQRDecimalParserTests {
    @Test("Parses plain integer and decimal values")
    func parsesPlainValues() {
        #expect(MainQRDecimalParser.parseDecimal("123") == Decimal(string: "123"))
        #expect(MainQRDecimalParser.parseDecimal("123.45") == Decimal(string: "123.45"))
        #expect(MainQRDecimalParser.parseDecimal("0.5") == Decimal(string: "0.5"))
    }

    @Test("Parses a leading-dot fraction")
    func parsesLeadingDot() {
        #expect(MainQRDecimalParser.parseDecimal(".5") == Decimal(string: "0.5"))
    }

    @Test("Treats a comma as a decimal separator")
    func commaAsDecimalSeparator() {
        #expect(MainQRDecimalParser.parseDecimal("1234,56789") == Decimal(string: "1234.56789"))
        // A single comma is interpreted as a decimal point, never as a thousands separator.
        #expect(MainQRDecimalParser.parseDecimal("1,000") == Decimal(string: "1.000"))
    }

    @Test("Parses signed values")
    func parsesSignedValues() {
        #expect(MainQRDecimalParser.parseDecimal("+1.5") == Decimal(string: "1.5"))
        #expect(MainQRDecimalParser.parseDecimal("-1.5") == Decimal(string: "-1.5"))
    }

    @Test("Parses scientific notation")
    func parsesScientificNotation() {
        #expect(MainQRDecimalParser.parseDecimal("1e3") == Decimal(string: "1000"))
        #expect(MainQRDecimalParser.parseDecimal("1.5E-2") == Decimal(string: "0.015"))
    }

    @Test("Trims surrounding whitespace")
    func trimsWhitespace() {
        #expect(MainQRDecimalParser.parseDecimal("  12.5  ") == Decimal(string: "12.5"))
    }

    @Test("Returns nil for empty or whitespace-only input", arguments: ["", " ", "\n", "\t "])
    func returnsNilForEmpty(_ input: String) {
        #expect(MainQRDecimalParser.parseDecimal(input) == nil)
    }

    @Test(
        "Returns nil for non-numeric or malformed input",
        arguments: [
            "abc",
            "1.2.3",
            "1,234.56", // mixed decimal and group separators
            "1.234,56", // mixed decimal and group separators
            "1.", // trailing separator without a fraction
            "1 000", // internal whitespace
            "0x10",
            "--1",
            "1e", // incomplete exponent
        ]
    )
    func returnsNilForMalformed(_ input: String) {
        #expect(MainQRDecimalParser.parseDecimal(input) == nil)
    }
}
