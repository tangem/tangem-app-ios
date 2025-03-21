//
//  VisaPinValidator.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaPinValidator {
    public let pinCodeLength = 4

    public init() {}

    public func validatePinCode(_ pin: String) throws(PinValidationError) {
        guard
            pin.count == pinCodeLength,
            pin.allSatisfy(\.isNumber)
        else {
            throw .invalidLength
        }

        let digits = pin.map { $0.wholeNumberValue! }

        if Set(digits).count == 1 {
            throw .repeatedDigits
        }

        let banList: Set<String> = [
            "0987",
        ]

        let isAscending = zip(digits, digits.dropFirst()).allSatisfy { $1 == $0 + 1 }
        let isDescending = zip(digits, digits.dropFirst()).allSatisfy { $1 == $0 - 1 }

        if isAscending || isDescending || banList.contains(pin) {
            throw .sequentialDigits
        }
    }
}

public extension VisaPinValidator {
    enum PinValidationError: Error {
        case invalidLength
        case repeatedDigits
        case sequentialDigits
    }
}
