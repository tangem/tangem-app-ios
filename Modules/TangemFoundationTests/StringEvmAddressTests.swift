//
//  StringEvmAddressTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation

@Suite("String EVM address check")
struct StringEvmAddressTests {
    @Test("Forty hex digits behind the hex prefix are an EVM address in either letter case", arguments: [
        "0x5E55000000000000000000000000000000000001",
        "0x5e55000000000000000000000000000000000001",
    ])
    func hexAddressIsAccepted(_ address: String) {
        #expect(address.isEvmAddress)
    }

    @Test("Anything but forty ASCII hex digits behind the hex prefix is not an EVM address", arguments: [
        "",
        "5E55000000000000000000000000000000000001",
        "0x5E550000000000000000000000000000000001",
        "0x5E5500000000000000000000000000000000000100",
        "0x5E5500000000000000000000000000000000000Z",
        "0x５E55000000000000000000000000000000000001",
        "0xＡE55000000000000000000000000000000000001",
    ])
    func otherStringsAreRejected(_ address: String) {
        #expect(!address.isEvmAddress)
    }
}
