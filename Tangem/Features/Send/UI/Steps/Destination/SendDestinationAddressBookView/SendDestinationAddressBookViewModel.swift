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
        // Decide wallet-name disambiguation over the full contact set, not just the shown prefix, so the
        // compact list labels match the full "View All" screen.
        let showsWalletName = contacts.unique(by: \.contact.walletId).count > 1
        let displayed = Array(contacts.prefix(limit))

        displayedContacts = displayed.map { item in
            let walletName = showsWalletName ? item.walletName : nil
            return AddressBookContactViewModel(contact: item.contact, walletName: walletName) {
                tapAction(item.contact)
            }
        }

        self.viewAllAction = viewAllAction
    }
}
