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
        id = contact.id.uuidString
        title = contact.name
        subtitle = Localization.addressBookAddresses(contact.addresses.count)
        letter = contact.firstLetter
        iconColor = AccountModelUtils.UI.iconColor(from: contact.color)

        self.action = action
    }
}
