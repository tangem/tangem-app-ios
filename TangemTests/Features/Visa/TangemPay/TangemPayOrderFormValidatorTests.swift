//
//  TangemPayOrderFormValidatorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("TangemPayOrderFormValidator")
struct TangemPayOrderFormValidatorTests {
    @Test("Name charset accepts Latin letters, spaces and hyphens", arguments: [
        "JOHN",
        "Mary Jane",
        "Saint-Denis",
        "",
    ])
    func nameCharsetAccepts(_ input: String) {
        #expect(TangemPayOrderFormValidator.isNameCharsetValid(input))
    }

    @Test("Name charset rejects digits, punctuation, accents and non-Latin scripts", arguments: [
        "O'Brien",
        "O\u{2019}Brien",
        "Mary2",
        "A.B",
        "A/B",
        "A,B",
        "A(B)",
        "A:B",
        "José",
        "北京",
    ])
    func nameCharsetRejects(_ input: String) {
        #expect(!TangemPayOrderFormValidator.isNameCharsetValid(input))
    }

    @Test("Shipping address charset accepts Latin letters, digits, spaces and the allowed punctuation", arguments: [
        "JOHN Doe 42",
        "Apt 5/7",
        "St. John",
        "O'Brien",
        "Apt #5",
        "Smith & Sons",
        "Block (A) #5",
        "Block (A) #5 & Sons",
        "Unit 10",
        "°",
        "JOHN\u{00A0}DOE",
        "",
    ])
    func shippingAddressCharsetAccepts(_ input: String) {
        #expect(TangemPayOrderFormValidator.isShippingAddressCharsetValid(input))
    }

    @Test("Shipping address charset rejects colon, accents and non-Latin scripts", arguments: [
        "Unit: 10",
        "José",
        "São Paulo",
        "São Paulo".decomposedStringWithCanonicalMapping,
        "Kraków",
        "Müller Straße 10",
        "北京",
        "A×B",
    ])
    func shippingAddressCharsetRejects(_ input: String) {
        #expect(!TangemPayOrderFormValidator.isShippingAddressCharsetValid(input))
    }

    @Test("Postal charset accepts Latin letters, digits, spaces and hyphens", arguments: [
        "12345",
        "SW1A 1AA",
        "123-45",
        "",
    ])
    func postalCharsetAccepts(_ input: String) {
        #expect(TangemPayOrderFormValidator.isPostalCharsetValid(input))
    }

    @Test("Postal charset rejects dots, slashes, other punctuation, accents and non-Latin scripts", arguments: [
        "12.345",
        "123/45",
        "Apt #5",
        "José",
        "北京",
    ])
    func postalCharsetRejects(_ input: String) {
        #expect(!TangemPayOrderFormValidator.isPostalCharsetValid(input))
    }

    @Test("Emboss charset accepts ASCII Latin and its punctuation", arguments: [
        "JOHN DOE",
        "Mary-Jane Smith Jr.",
        "O'BRIEN",
        "Smith & Sons",
        "",
    ])
    func embossCharsetAccepts(_ input: String) {
        #expect(TangemPayOrderFormValidator.isEmbossCharsetValid(input))
    }

    @Test("Emboss charset rejects accents, non-Latin scripts and disallowed punctuation", arguments: [
        "Unit: 10",
        "José",
        "北京",
    ])
    func embossCharsetRejects(_ input: String) {
        #expect(!TangemPayOrderFormValidator.isEmbossCharsetValid(input))
    }

    @Test("Off-ramp address charset keeps Latin accents", arguments: [
        "São Paulo",
        "Île-de-France",
        "Kraków",
        "Müller Straße 10",
        "São Paulo".decomposedStringWithCanonicalMapping,
        "Smith & Sons",
        "",
    ])
    func offrampAddressCharsetAccepts(_ input: String) {
        #expect(TangemPayOrderFormValidator.isAddressCharsetValid(input))
    }

    @Test("Off-ramp address charset rejects non-Latin scripts and disallowed symbols", arguments: [
        "北京",
        "A×B",
    ])
    func offrampAddressCharsetRejects(_ input: String) {
        #expect(!TangemPayOrderFormValidator.isAddressCharsetValid(input))
    }

    @Test("A non-Latin letter is detected", arguments: [
        "José",
        "São Paulo",
        "Kraków",
        "Müller Straße 10",
        "Włodzimierz",
        "北京",
    ])
    func detectsNonLatinLetter(_ input: String) {
        #expect(TangemPayOrderFormValidator.containsNonLatinLetter(input))
    }

    @Test("ASCII letters, digits and punctuation are not non-Latin letters", arguments: [
        "Unit: 10",
        "12.345",
        "Apt #5",
        "JOHN Doe 42",
        "",
    ])
    func ignoresAsciiAndSymbols(_ input: String) {
        #expect(!TangemPayOrderFormValidator.containsNonLatinLetter(input))
    }

    @Test("Typing a character at the limit is blocked")
    func typingAtLimitIsBlocked() {
        let capped = TangemPayOrderFormValidator.capped(
            "123456789",
            replacing: NSRange(location: 9, length: 0),
            with: "0",
            maxLength: 9
        )
        #expect(capped == "123456789")
    }

    @Test("Pasting past the limit truncates to what fits")
    func pastingTruncatesToLimit() {
        let capped = TangemPayOrderFormValidator.capped(
            "",
            replacing: NSRange(location: 0, length: 0),
            with: "0123456789",
            maxLength: 9
        )
        #expect(capped == "012345678")
    }

    @Test("Pasting a 101-character string truncates to the 100-character limit")
    func pastingTruncatesToHundred() {
        let paste = String(repeating: "a", count: 101)
        let capped = TangemPayOrderFormValidator.capped(
            "",
            replacing: NSRange(location: 0, length: 0),
            with: paste,
            maxLength: 100
        )
        #expect(capped?.count == 100)
    }

    @Test("An edit that stays within the limit is applied unchanged")
    func editWithinLimitPassesThrough() {
        let capped = TangemPayOrderFormValidator.capped(
            "abc",
            replacing: NSRange(location: 3, length: 0),
            with: "d",
            maxLength: 9
        )
        #expect(capped == nil)
    }

    @Test("Replacing a selection counts the removed range")
    func replacingSelectionCountsRemovedRange() {
        let capped = TangemPayOrderFormValidator.capped(
            "HELLO",
            replacing: NSRange(location: 0, length: 5),
            with: "WORLDWIDE",
            maxLength: 5
        )
        #expect(capped == "WORLD")
    }
}
