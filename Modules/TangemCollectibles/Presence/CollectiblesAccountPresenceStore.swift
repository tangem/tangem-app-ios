//
//  CollectiblesAccountPresenceStore.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import TangemFoundation

public protocol CollectiblesAccountPresenceStore {
    func contains(_ userWalletId: UserWalletId) -> Bool
    func insert(_ userWalletId: UserWalletId)
    func remove(_ userWalletId: UserWalletId)
}
