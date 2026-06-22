//
//  AddressBooksRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol AddressBooksRoutable: AnyObject {
    func openAddContact(addressBookWallet: AddressBookWallet)
    func openEditContact(contact: AddressBookContact, addressBookWallet: AddressBookWallet)
}
