//
//  PolymarketCredentialsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

protocol PolymarketCredentialsRepository {
    func save(credentials: PolymarketL2Credentials, userWalletId: UserWalletId) throws
    func load(userWalletId: UserWalletId) -> PolymarketL2Credentials?
    func delete(userWalletId: UserWalletId)
}
