//
//  PolymarketCredentialsRepository.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public protocol PolymarketCredentialsRepository {
    func save(credentials: PolymarketL2Credentials, userWalletId: UserWalletId) throws
    func load(userWalletId: UserWalletId) -> PolymarketL2Credentials?
    func delete(userWalletId: UserWalletId)
    func clean(genericPasswordAccounts: [String])
}
