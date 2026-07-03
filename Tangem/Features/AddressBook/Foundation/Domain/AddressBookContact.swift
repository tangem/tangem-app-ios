//
//  AddressBookContact.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// A verified contact. By construction it always has a validated name and a non-empty set of verified
/// address entries, both scoped to a single wallet.
struct AddressBookContact: Hashable {
    let id: AddressBookContactID
    let walletId: UserWalletId
    let name: AddressBookContactName
    let appearance: AddressBookContactAppearance
    let entries: AddressBookContactVerifiedEntries
}
