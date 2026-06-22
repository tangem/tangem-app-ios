//
//  AddressBookContactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct AddressBookContactViewModel: Identifiable {
    let id: String

    let title: String
    let subtitle: String
    let letter: String
    let iconColor: Color

    let action: () -> Void

    init(contact: AddressBookContact, action: @escaping () -> Void) {
        let name = contact.name.value
        let color = AccountModel.CompositeIcon.Color(rawValue: contact.iconColor) ?? .azure

        id = contact.id.stringValue
        title = name
        subtitle = Localization.addressBookAddresses(contact.entries.addressCount)
        letter = "\(name.prefix(1).uppercased())"
        iconColor = AccountModelUtils.UI.iconColor(from: color)

        self.action = action
    }
}
