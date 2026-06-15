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

    init(contact: ContactReadModel, action: @escaping () -> Void) {
        let name = contact.name.value

        let addressCount: Int = switch contact {
        case .valid(let value): value.entries.count
        case .allEntriesInvalid: 0
        }

        id = contact.id.stringValue
        title = name
        subtitle = Localization.addressBookAddresses(addressCount)
        letter = "\(name.prefix(1).uppercased())"

        self.action = action
    }
}
