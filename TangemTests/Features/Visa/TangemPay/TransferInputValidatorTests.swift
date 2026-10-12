//
//  TransferInputValidatorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("TransferInputValidator")
struct TransferInputValidatorTests {
    @Test("Amount below the minimum shows the range error")
    func amountBelowMinimum_isOutOfRange() {
        let state = TransferInputValidator.validate(amount: 0.5, available: 100)

        #expect(state == .outOfRange(min: 1, max: 10_000))
    }

    @Test("Amount above the maximum shows the range error")
    func amountAboveMaximum_isOutOfRange() {
        let state = TransferInputValidator.validate(amount: 10_001, available: 20_000)

        #expect(state == .outOfRange(min: 1, max: 10_000))
    }

    @Test("Amount in range but above balance minus fee shows not enough funds")
    func amountInRangeAboveAvailable_isNotEnoughFunds() {
        let state = TransferInputValidator.validate(amount: 500, available: 100)

        #expect(state == .notEnoughFunds)
    }

    @Test("Amount in range and within balance minus fee is valid")
    func amountInRangeWithinAvailable_isValid() {
        let state = TransferInputValidator.validate(amount: 100, available: 500)

        #expect(state == .valid)
    }
}
