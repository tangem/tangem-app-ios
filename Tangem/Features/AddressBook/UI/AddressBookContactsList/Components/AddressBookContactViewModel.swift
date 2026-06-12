//
//  AddressBookContactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

struct AddressBookContactViewModel: Identifiable {
    var id: String { title }

    let title: String
    let subtitle: String
    let letter: String

    let action: () -> Void

    init(contact: AddressBookContact, action: @escaping () -> Void) {
        title = contact.name
        subtitle = Localization.addressBookAddresses(contact.addresses.count)
        letter = contact.firstLetter

        self.action = action
    }
}
