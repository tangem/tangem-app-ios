//
//  AddressBookUIContact.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct AddressBookUIContact: Hashable, Identifiable {
    var firstLetter: String { "\(name.prefix(1).uppercased())" }

    let id: UUID
    let name: String
    let icon: String
    let color: AccountModel.CompositeIcon.Color
    let userWalletId: UserWalletId
    let addresses: [AddressBookAddress]
}
