//
//  TangemPayOrderCardDataField.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import UIKit

struct TangemPayOrderCardDataField: Identifiable {
    let id: ID
    let title: String
    var text = ""
    var isOptional = false
    var isEditable = true
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var mask: String?
    var error: Error?

    enum ID {
        case nameOnCard
        case country
        case email
        case firstName
        case lastName
        case region
        case city
        case addressLine1
        case addressLine2
        case postalCode
        case phone
    }

    enum Error: Equatable {
        case required
        case invalid
        case nonLatin

        var message: String {
            switch self {
            case .required: Localization.tangempayOrderDataFieldRequired
            case .invalid: Localization.tangempayOrderDataFieldInvalid
            case .nonLatin: Localization.tangempayOrderDataFieldLatinOnly
            }
        }
    }
}

extension TangemPayOrderCardDataField {
    var inputMask: TangemPayInputMask? {
        mask.flatMap(TangemPayInputMask.init)
    }

    var maxLength: Int? {
        switch id {
        case .firstName, .lastName, .region, .city:
            50
        case .addressLine1, .addressLine2:
            100
        case .postalCode:
            9
        case .nameOnCard, .country, .email, .phone:
            nil
        }
    }

    /// The error the field would report right now; `error` is the one currently shown.
    var currentError: Error? {
        guard isEditable else {
            return nil
        }

        guard !isEffectivelyEmpty else {
            return isOptional ? nil : .required
        }

        let value = text.trimmed()

        return id == .phone ? phoneError(in: value) : charsetError(in: value)
    }

    var liveError: Error? {
        guard isEditable, id != .phone else {
            return nil
        }

        return charsetError(in: text.trimmed())
    }
}

private extension TangemPayOrderCardDataField {
    enum Constants {
        static let e164DigitBounds = 7 ... 15
    }

    var isEffectivelyEmpty: Bool {
        if id == .phone, let inputMask {
            return inputMask.digitCount(in: text) == 0
        }
        return text.trimmed().isEmpty
    }

    func charsetError(in value: String) -> Error? {
        let isCharsetValid = switch id {
        case .nameOnCard: TangemPayOrderFormValidator.isEmbossCharsetValid(value)
        case .firstName, .lastName: TangemPayOrderFormValidator.isNameCharsetValid(value)
        case .region, .city, .addressLine1, .addressLine2: TangemPayOrderFormValidator.isShippingAddressCharsetValid(value)
        case .postalCode: TangemPayOrderFormValidator.isPostalCharsetValid(value)
        case .country, .email, .phone: true
        }

        guard !isCharsetValid else {
            return nil
        }

        return TangemPayOrderFormValidator.containsNonLatinLetter(value) ? .nonLatin : .invalid
    }

    func phoneError(in value: String) -> Error? {
        guard let inputMask else {
            return Constants.e164DigitBounds.contains(value.count(where: \.isWholeNumber)) ? nil : .invalid
        }

        return inputMask.digitCount(in: value) == inputMask.slotCount ? nil : .invalid
    }
}
