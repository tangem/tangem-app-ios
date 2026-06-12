//
//  ContactNameTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("ContactName validation")
struct ContactNameTests {
    @Test("trims and accepts a valid name")
    func valid() throws {
        #expect(try ContactName(validating: "  Binance  ").value == "Binance")
    }

    @Test("accepts digits, spaces and non-latin scripts")
    func allowedCharacters() throws {
        #expect(try ContactName(validating: "Биржа 123").value == "Биржа 123")
        #expect(try ContactName(validating: "交易所").value == "交易所")
    }

    @Test("accepts exactly 50 characters")
    func boundary() throws {
        #expect(try ContactName(validating: String(repeating: "a", count: 50)).value.count == 50)
    }

    @Test("rejects an empty / whitespace-only name")
    func empty() {
        #expect(throws: AddressBookValidationError.self) {
            _ = try ContactName(validating: "   ")
        }
    }

    @Test("rejects more than 50 characters")
    func tooLong() {
        #expect(throws: AddressBookValidationError.self) {
            _ = try ContactName(validating: String(repeating: "a", count: 51))
        }
    }

    @Test("rejects emoji")
    func emoji() {
        #expect(throws: AddressBookValidationError.self) {
            _ = try ContactName(validating: "Wallet 🚀")
        }
    }

    @Test("rejects HTML / angle brackets")
    func html() {
        #expect(throws: AddressBookValidationError.self) {
            _ = try ContactName(validating: "<script>alert</script>")
        }
    }

    @Test("rejects line breaks")
    func newline() {
        #expect(throws: AddressBookValidationError.self) {
            _ = try ContactName(validating: "Line1\nLine2")
        }
    }
}
