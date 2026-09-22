//
//  TangemPayFormField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct TangemPayFormField: Identifiable {
    let id: ID
    let title: String
    var placeholder: String
    var text = ""
    var error: Error?
    var onSelect: (() -> Void)?

    enum ID: Hashable {
        case email
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
        case bankName
        case bankRegion
        case bankCity
        case bankLine1
        case bankPostalCode
    }

    enum Error: Hashable {
        case required
        case invalidFormat
        case invalidEmail
        case routingNumber
        case nonLatin

        var message: String {
            switch self {
            case .invalidEmail: Localization.commonErrorEmailIncorrectFormat
            case .required: Localization.tangempayOrderDataFieldRequired
            case .invalidFormat: Localization.tangempayWithdrawBankFieldErrorInvalidFormat
            case .routingNumber: Localization.tangempayWithdrawBankFieldErrorRoutingNumber
            case .nonLatin: Localization.tangempayOrderDataFieldLatinOnly
            }
        }
    }
}

// MARK: - Validation

extension TangemPayFormField {
    var isOptional: Bool {
        id.isOptional
    }

    var isSelectable: Bool {
        onSelect != nil
    }

    var currentError: Error? {
        OfframpFormValidator.error(for: id, in: text)
    }
}

// MARK: - Input traits

extension TangemPayFormField.ID {
    var isOptional: Bool {
        self == .line2
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .email:
            .emailAddress

        case .accountNumber, .routingNumber, .postalCode, .bankPostalCode:
            .numberPad

        case .firstName, .lastName, .businessName, .countryCode, .region, .city, .line1, .line2,
             .bankName, .bankRegion, .bankCity, .bankLine1:
            .default
        }
    }

    var textContentType: UITextContentType? {
        switch self {
        case .email: .emailAddress
        case .accountNumber, .routingNumber, .countryCode, .region, .bankRegion: nil
        case .firstName: .givenName
        case .lastName: .familyName
        case .businessName, .bankName: .organizationName
        case .city, .bankCity: .addressCity
        case .line1, .bankLine1: .streetAddressLine1
        case .line2: .streetAddressLine2
        case .postalCode, .bankPostalCode: .postalCode
        }
    }

    var autocapitalization: TextInputAutocapitalization {
        switch self {
        case .countryCode, .region, .bankRegion,
             .firstName, .lastName, .businessName, .city, .line1, .line2,
             .bankName, .bankCity, .bankLine1:
            .words

        case .email, .accountNumber, .routingNumber, .postalCode, .bankPostalCode:
            .never
        }
    }
}
