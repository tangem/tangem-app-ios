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

    enum Error {
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

    /// The error the field would report right now; `error` is the one currently shown, set on focus loss.
    var currentError: Error? {
        guard isEditable else {
            return nil
        }

        let value = text.trimmed()

        guard !value.isEmpty else {
            return isOptional ? nil : .required
        }

        switch id {
        case .phone:
            return phoneError(in: value)
        case .nameOnCard:
            return TangemPayOrderFormValidator.isEmbossCharsetValid(value) ? nil : .nonLatin
        default:
            return TangemPayOrderFormValidator.isAddressCharsetValid(value) ? nil : .nonLatin
        }
    }
}

private extension TangemPayOrderCardDataField {
    enum Constants {
        static let e164DigitBounds = 7 ... 15
    }

    func phoneError(in value: String) -> Error? {
        guard let inputMask else {
            return Constants.e164DigitBounds.contains(value.count(where: \.isWholeNumber)) ? nil : .invalid
        }

        return inputMask.digitCount(in: value) == inputMask.slotCount ? nil : .invalid
    }
}
