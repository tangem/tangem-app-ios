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
    let iconViewData: AddressBookContactNameIconViewData

    let action: () -> Void

    init(contact: AddressBookContact, walletName: String? = nil, action: @escaping () -> Void) {
        let name = contact.name.value
        let addresses = Localization.addressBookAddresses(contact.entries.addressCount)

        id = contact.id.stringValue
        title = name
        subtitle = [walletName, addresses].compactMap { $0 }.joined(separator: " \(AppConstants.dotSign) ")
        iconViewData = .init(contact: contact)

        self.action = action
    }
}
