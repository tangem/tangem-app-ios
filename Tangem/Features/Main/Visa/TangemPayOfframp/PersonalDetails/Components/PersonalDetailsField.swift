//
//  PersonalDetailsField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct PersonalDetailsField: Identifiable {
    let id: ID
    let title: String
    let placeholder: String
    var text = ""
    var error: Error?

    enum ID: Hashable {
        case accountNumber
        case routingNumber
        case firstName
        case lastName
        case businessName
        case countryCode
        case region
        case city
        case line1
        case line2
        case postalCode
    }

    enum Error: Hashable {
        case required
        case invalidFormat
        case routingNumber
        case nonLatin

        var message: String {
            // [REDACTED_TODO_COMMENT]
            switch self {
            case .required: "Required field"
            case .invalidFormat: "Invalid text format"
            case .routingNumber: "The routing number is incorrect"
            case .nonLatin: "Use Latin characters only"
            }
        }
    }
}

// MARK: - Validation

extension PersonalDetailsField {
    var isOptional: Bool {
        id.isOptional
    }

    var currentError: Error? {
        PersonalDetailsValidator.error(for: id, in: text)
    }
}

// MARK: - Input traits

extension PersonalDetailsField.ID {
    var isOptional: Bool {
        self == .line2
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .accountNumber, .routingNumber, .postalCode:
            .numberPad

        case .firstName, .lastName, .businessName, .countryCode, .region, .city, .line1, .line2:
            .default
        }
    }

    var textContentType: UITextContentType? {
        switch self {
        case .accountNumber, .routingNumber, .countryCode, .region: nil
        case .firstName: .givenName
        case .lastName: .familyName
        case .businessName: .organizationName
        case .city: .addressCity
        case .line1: .streetAddressLine1
        case .line2: .streetAddressLine2
        case .postalCode: .postalCode
        }
    }

    var autocapitalization: TextInputAutocapitalization {
        switch self {
        case .countryCode, .region:
            .characters

        case .firstName, .lastName, .businessName, .city, .line1, .line2:
            .words

        case .accountNumber, .routingNumber, .postalCode:
            .never
        }
    }
}
