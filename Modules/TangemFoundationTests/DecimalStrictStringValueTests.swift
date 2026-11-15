//
//  DecimalStrictStringValueTests.swift
//  TangemFoundationTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation

@Suite("Decimal strict string value")
struct DecimalStrictStringValueTests {
    @Test("Parses plain decimal notation exactly", arguments: ["0", "12", "12.5", "0.000000000000000001", "123456789012345678901234567890"])
    func parsesPlainNotation(string: String) {
        #expect(Decimal(strictStringValue: string) == Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")))
    }

    @Test("Rejects anything the lenient parser would cut or reinterpret", arguments: ["", " 1", "1 ", "+1", "-1", ".5", "1.", "1,5", "1e5", "12abc", "0x10", "1.2.3", "١٢"])
    func rejectsOtherNotations(string: String) {
        #expect(Decimal(strictStringValue: string) == nil)
    }
}
