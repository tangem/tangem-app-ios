//
//  AddressBookContactsListRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol AddressBookContactsListRoutable: AnyObject {
    func openAddContact(walletId: UserWalletId)
    func openEditContact(contact: AddressBookContact, walletId: UserWalletId)
}
