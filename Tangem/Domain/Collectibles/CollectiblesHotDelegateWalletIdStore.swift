//
//  CollectiblesHotDelegateWalletIdStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Names the delegate wallet a real wallet signs collectibles with.
protocol CollectiblesHotDelegateWalletIdStore {
    func delegateWalletId(for userWalletId: UserWalletId) throws -> UserWalletId?
    func setDelegateWalletId(_ delegateWalletId: UserWalletId?, for userWalletId: UserWalletId) throws
}
