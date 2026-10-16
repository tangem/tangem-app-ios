//
//  TangemPayOrderCardDataFieldTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("TangemPayOrderCardDataField error resolution")
struct TangemPayOrderCardDataFieldTests {
    @Test("A non-Latin letter reports the Latin-only error")
    func nonLatinLetterReportsLatinOnly() {
        #expect(field(.firstName, "José").currentError == .nonLatin)
        #expect(field(.city, "Kraków").currentError == .nonLatin)
        #expect(field(.postalCode, "北京").currentError == .nonLatin)
    }

    @Test("A disallowed character that is not a letter reports the generic invalid error")
    func disallowedSymbolReportsInvalid() {
        #expect(field(.city, "Unit: 10").currentError == .invalid)
        #expect(field(.addressLine1, "Apt @ 5").currentError == .invalid)
        #expect(field(.firstName, "Mary2").currentError == .invalid)
        #expect(field(.postalCode, "12.345").currentError == .invalid)
    }

    @Test("A value within the charset has no error")
    func allowedValueHasNoError() {
        #expect(field(.addressLine1, "Apt #5 & Sons").currentError == nil)
        #expect(field(.firstName, "Mary-Jane").currentError == nil)
        #expect(field(.postalCode, "SW1A 1AA").currentError == nil)
    }

    @Test("An empty required field reports required")
    func emptyRequiredFieldReportsRequired() {
        #expect(field(.firstName, "").currentError == .required)
    }

    @Test("liveError surfaces the character error but never required")
    func liveErrorSurfacesCharacterErrorOnly() {
        #expect(field(.city, "Unit: 10").liveError == .invalid)
        #expect(field(.city, "José").liveError == .nonLatin)
        #expect(field(.firstName, "").liveError == nil)
    }

    private func field(_ id: TangemPayOrderCardDataField.ID, _ text: String) -> TangemPayOrderCardDataField {
        TangemPayOrderCardDataField(id: id, title: "", text: text)
    }
}
