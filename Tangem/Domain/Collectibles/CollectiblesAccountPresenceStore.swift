//
//  CollectiblesAccountPresenceStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol CollectiblesAccountPresenceStore {
    func contains(_ userWalletId: UserWalletId) -> Bool
    func insert(_ userWalletId: UserWalletId)
    func remove(_ userWalletId: UserWalletId)
}
