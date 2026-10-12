//
//  CollectiblesSessionKeyWalletIdStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Names the session key wallet a real wallet signs collectibles with.
protocol CollectiblesSessionKeyWalletIdStore {
    func sessionKeyWalletId(for userWalletId: UserWalletId) throws -> UserWalletId?
    func setSessionKeyWalletId(_ sessionKeyWalletId: UserWalletId?, for userWalletId: UserWalletId) throws
}
