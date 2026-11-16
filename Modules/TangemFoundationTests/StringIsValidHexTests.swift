//
//  StringIsValidHexTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation

@Suite("String hex check")
struct StringIsValidHexTests {
    @Test("An even number of ASCII hex digits is hex in any letter case", arguments: [
        "0123456789abcdef",
        "0123456789ABCDEF",
        "aBcDeF09",
    ])
    func asciiHexIsAccepted(_ string: String) {
        #expect(string.isValidHex)
    }

    @Test("An empty string is hex")
    func emptyStringIsAccepted() {
        #expect("".isValidHex)
    }

    @Test("A string with anything but ASCII hex digits or an odd number of them is not hex", arguments: [
        "1a\u{301}",
        "abc\n",
        "abc\r\n",
        "0x12",
        "c\u{430}f\u{435}",
        "\u{FF10}0",
        "abc",
    ])
    func otherStringsAreRejected(_ string: String) {
        #expect(!string.isValidHex)
    }

    @Test("A 32-byte value in hex with a combining mark on its last digit is not hex")
    func longHexWithCombiningMarkIsRejected() {
        let string = String(repeating: "ab", count: 32) + "\u{301}"

        #expect(!string.isValidHex)
    }
}
