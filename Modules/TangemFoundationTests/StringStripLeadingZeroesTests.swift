//
//  StringStripLeadingZeroesTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation

@Suite("String leading zeroes")
struct StringStripLeadingZeroesTests {
    @Test("Only the zeroes at the very start are dropped", arguments: zip(
        ["000123", "1000", "0a0", "0x00", "00\n00", " 001"],
        ["123", "1000", "a0", "x00", "\n00", " 001"]
    ))
    func leadingZeroesAreDropped(_ string: String, expected: String) {
        #expect(string.stripLeadingZeroes() == expected)
    }

    @Test("A string of zeroes only becomes empty", arguments: ["0", "0000", ""])
    func zeroesOnlyBecomeEmpty(_ string: String) {
        #expect(string.stripLeadingZeroes() == "")
    }
}
