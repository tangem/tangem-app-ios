//
//  AddressBook.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct AddressBook: Equatable {
    let userWalletId: UserWalletId
    let contacts: [AddressBookUIContact]
}
