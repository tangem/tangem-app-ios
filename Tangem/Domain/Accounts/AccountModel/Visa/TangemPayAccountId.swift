//
//  TangemPayAccountId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TangemPayAccountId: Hashable {
    let userWalletId: UserWalletId
}

// MARK: - AccountModelPersistentIdentifierConvertible

extension TangemPayAccountId: AccountModelPersistentIdentifierConvertible {
    func toPersistentIdentifier() -> String {
        "Tpay/\(userWalletId.stringValue)"
    }
}
