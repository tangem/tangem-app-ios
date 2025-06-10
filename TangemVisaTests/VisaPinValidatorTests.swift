//
//  VisaPinValidatorTests.swift
//  TangemVisaTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemVisa

@Suite("Visa PIN validator tests")
struct VisaPinValidatorTests {
    private let validator = VisaPinValidator()

    @Test("Valid PIN codes test", arguments: [
        "1354", "8745", "7890", "0249",
    ])
    func validPinCodes(_ pinCode: String) {
        #expect(throws: Never.self, performing: {
            try validator.validatePinCode(pinCode)
        })
    }

    @Test("Invalid PIN codes test", arguments: [
        "0987", "1111", "1234", "6789",
        "12389034", "658", "0000",
        "sfew", "jfiowefiow", "jfr", ".,/\""
    ])
    func invalidPinCodes(_ pinCode: String) {
        #expect(throws: VisaPinValidator.PinValidationError.self, performing: {
            try validator.validatePinCode(pinCode)
        })
    }
}
