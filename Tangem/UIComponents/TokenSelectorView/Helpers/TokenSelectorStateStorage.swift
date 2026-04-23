//
//  TokenSelectorStateStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol TokenSelectorStateStorage: AnyObject {
    func initialize()

    var selectedWalletId: UserWalletId? { get set }
    func makeAccountStateStorage(for userWalletId: UserWalletId) -> ExpandableAccountItemStateStorage
}

// MARK: - Injection

extension InjectedValues {
    var tokenSelectorStateStorage: TokenSelectorStateStorage {
        get { Self[TokenSelectorStateStorageKey.self] }
        set { Self[TokenSelectorStateStorageKey.self] = newValue }
    }
}

private struct TokenSelectorStateStorageKey: InjectionKey {
    static var currentValue: any TokenSelectorStateStorage = CommonTokenSelectorStateStorage()
}
