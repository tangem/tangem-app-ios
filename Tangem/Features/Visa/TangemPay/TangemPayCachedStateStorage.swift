//
//  TangemPayCachedStateStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol TangemPayCachedStateStorage {
    func cachedLocalState(customerWalletId: String) -> TangemPayCachedLocalState?
    func saveCachedLocalState(_ state: TangemPayCachedLocalState, customerWalletId: String)
}
