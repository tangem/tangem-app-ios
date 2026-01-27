//
//  DefaultAccountFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct DefaultAccountFactory {
    private let userWalletId: UserWalletId
    private let defaultBlockchains: [TokenItem]

    init(userWalletId: UserWalletId, defaultBlockchains: [TokenItem]) {
        self.userWalletId = userWalletId
        self.defaultBlockchains = defaultBlockchains
    }

    func makeDefaultAccount() -> StoredCryptoAccount {
        let config = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let tokens = StoredEntryConverter.convertToStoredEntries(defaultBlockchains)

        return StoredCryptoAccount(config: config, tokenListAppearance: .default, tokens: tokens)
    }
}
