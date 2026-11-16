//
//  CollectiblesAccountId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// One per wallet, keyed like its account list entry so that the backend order places it like any other account.
struct CollectiblesAccountId: Hashable {
    let userWalletId: UserWalletId
}

// MARK: - AccountModelPersistentIdentifierConvertible

extension CollectiblesAccountId: AccountModelPersistentIdentifierConvertible {
    func toPersistentIdentifier() -> AnyHashable {
        AccountModelUtils.collectiblesAccountDerivationIdentity.toPersistentIdentifier()
    }
}
