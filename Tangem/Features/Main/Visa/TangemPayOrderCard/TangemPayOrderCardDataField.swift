//
//  TangemPayOrderCardDataField.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

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
}
