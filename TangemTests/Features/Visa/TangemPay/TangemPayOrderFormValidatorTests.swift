//
//  TangemPayOrderFormValidatorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("TangemPayOrderFormValidator charset rules")
struct TangemPayOrderFormValidatorTests {
    @Test("Shipping charset accepts ASCII Latin, digits and the allowed punctuation", arguments: [
        "JOHN Doe 42",
        "Apt 5/7",
        "Saint-Denis",
        "St. John",
        "O'Brien",
        "Block (A)",
        "Unit: 10",
        "O\u{2019}BRIEN",
        "JOHN\u{00A0}DOE",
        "",
    ])
    func shippingCharsetAccepts(_ input: String) {
        #expect(TangemPayOrderFormValidator.isShippingCharsetValid(input))
    }

    @Test("Shipping charset rejects accents, non-Latin scripts and disallowed punctuation", arguments: [
        "José",
        "São Paulo",
        "São Paulo".decomposedStringWithCanonicalMapping,
        "Kraków",
        "Müller Straße 10",
        "北京",
        "Smith & Sons",
        "Apt #5",
        "john@doe",
    ])
    func shippingCharsetRejects(_ input: String) {
        #expect(!TangemPayOrderFormValidator.isShippingCharsetValid(input))
    }

    @Test("Emboss charset (name on card) accepts ASCII Latin and its punctuation", arguments: [
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

    @Test("Address charset (off-ramp) keeps Latin accents", arguments: [
        "São Paulo",
        "Île-de-France",
        "Kraków",
        "Müller Straße 10",
        "São Paulo".decomposedStringWithCanonicalMapping,
        "Smith & Sons",
        "",
    ])
    func addressCharsetAccepts(_ input: String) {
        #expect(TangemPayOrderFormValidator.isAddressCharsetValid(input))
    }

    @Test("Address charset rejects non-Latin scripts and disallowed symbols", arguments: [
        "北京",
        "A×B",
    ])
    func addressCharsetRejects(_ input: String) {
        #expect(!TangemPayOrderFormValidator.isAddressCharsetValid(input))
    }
}
