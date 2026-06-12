//
//  Contact.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// A verified contact. By construction it always has a validated name and at least one verified
/// address entry, both scoped to a single wallet.
struct Contact: Hashable {
    /// Maximum number of address entries a single contact may hold (enforced at mutation time).
    static let maxEntries = 20

    let id: ContactID
    let walletId: UserWalletId
    let name: ContactName
    let entries: NonEmptyArray<VerifiedAddressEntry>
}
