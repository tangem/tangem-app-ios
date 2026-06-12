//
//  AddressBookContactsListRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddressBookContactsListRoutable: AnyObject {
    func openAddContact()
    func openEditContact(contact: AddressBookContact)
}
