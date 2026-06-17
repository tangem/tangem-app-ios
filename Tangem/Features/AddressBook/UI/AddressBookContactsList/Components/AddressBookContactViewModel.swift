//
//  AddressBookContactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

struct AddressBookContactViewModel: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let letter: String

    let action: () -> Void

    init(contact: AddressBookContact, action: @escaping () -> Void) {
        let name = contact.name.value

        id = contact.id.stringValue
        title = name
        subtitle = Localization.addressBookAddresses(contact.entries.addressCount)
        letter = "\(name.prefix(1).uppercased())"

        self.action = action
    }
}
