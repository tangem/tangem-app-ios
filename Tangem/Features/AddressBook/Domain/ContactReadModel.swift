//
//  ContactReadModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// What the UI renders for a contact. Because a `Contact` can never be empty, the "all entries
/// failed verification" case — shown with a warning icon and no addresses — is modeled explicitly
/// rather than as an empty `Contact`.
enum ContactReadModel: Hashable {
    case valid(Contact)
    case allEntriesInvalid(id: ContactID, name: ContactName, walletId: UserWalletId)

    var id: ContactID {
        switch self {
        case .valid(let contact): contact.id
        case .allEntriesInvalid(let id, _, _): id
        }
    }

    var name: ContactName {
        switch self {
        case .valid(let contact): contact.name
        case .allEntriesInvalid(_, let name, _): name
        }
    }

    var walletId: UserWalletId {
        switch self {
        case .valid(let contact): contact.walletId
        case .allEntriesInvalid(_, _, let walletId): walletId
        }
    }
}
