//
//  SendDestinationAddressBookViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Contact model

struct SendDestinationAddressBookContact {
    let contact: AddressBookContact
    let walletName: String
}

// MARK: - View model

class SendDestinationAddressBookViewModel {
    let displayedContacts: [AddressBookContactViewModel]
    let viewAllAction: () -> Void

    init(
        contacts: [SendDestinationAddressBookContact],
        limit: Int,
        tapAction: @escaping (AddressBookContact) -> Void,
        viewAllAction: @escaping () -> Void
    ) {
        let displayed = Array(contacts.prefix(limit))
        // Show the wallet breadcrumb only when the displayed list spans more than one wallet,
        // mirroring the Address Book screen.
        let showsWalletName = Set(displayed.map { $0.contact.walletId.stringValue }).count > 1

        displayedContacts = displayed.map { item in
            AddressBookContactViewModel(contact: item.contact, walletName: showsWalletName ? item.walletName : nil) {
                tapAction(item.contact)
            }
        }
        self.viewAllAction = viewAllAction
    }
}
