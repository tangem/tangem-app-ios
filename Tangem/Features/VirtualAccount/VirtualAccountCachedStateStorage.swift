//
//  VirtualAccountCachedStateStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol VirtualAccountCachedStateStorage {
    func cachedLocalState(customerWalletId: String) -> VirtualAccountCachedLocalState?
    func saveCachedLocalState(_ state: VirtualAccountCachedLocalState, customerWalletId: String)
}
