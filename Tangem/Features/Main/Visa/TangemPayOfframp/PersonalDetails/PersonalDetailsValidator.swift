//
//  PersonalDetailsValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum PersonalDetailsValidator {
    static func error(
        for id: PersonalDetailsField.ID,
        in text: String
    ) -> PersonalDetailsField.Error? {
        let value = text.trimmed()

        guard !value.isEmpty else {
            return id.isOptional ? nil : .required
        }

        switch id {
        case .accountNumber:
            return matches(value, Constants.accountNumberPattern) ? nil : .invalidFormat

        case .routingNumber:
            return matches(value, Constants.routingNumberPattern) ? nil : .routingNumber

        case .postalCode:
            return matches(value, Constants.postalCodePattern) ? nil : .invalidFormat

        case .countryCode, .region:
            return matches(value, Constants.twoLetterCodePattern) ? nil : .invalidFormat

        case .firstName, .lastName, .businessName:
            return textError(in: value, lengthLimit: Constants.nameLengthLimit)

        case .city, .line1, .line2:
            return textError(in: value, lengthLimit: Constants.addressLengthLimit)
        }
    }
}

// MARK: - Rules

private extension PersonalDetailsValidator {
    enum Constants {
        static let accountNumberPattern = "^[0-9]{4,17}$"
        static let routingNumberPattern = "^[0-9]{9}$"
        static let postalCodePattern = "^[0-9]{5}(-[0-9]{4})?$"
        static let twoLetterCodePattern = "^[A-Za-z]{2}$"
        static let nameLengthLimit = 255
        static let addressLengthLimit = 100
    }

    static func matches(_ value: String, _ pattern: String) -> Bool {
        value.range(of: pattern, options: .regularExpression) != nil
    }

    static func textError(in value: String, lengthLimit: Int) -> PersonalDetailsField.Error? {
        guard value.count <= lengthLimit else {
            return .invalidFormat
        }

        return TangemPayOrderFormValidator.isAddressCharsetValid(value) ? nil : .nonLatin
    }
}
