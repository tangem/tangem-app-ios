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

    private var enrichedDefaultBlockchains: [TokenItem] {
        TokenItemsEnricher.enrichedWithBlockchainNetworksIfNeeded(defaultBlockchains)
    }

    init(userWalletId: UserWalletId, defaultBlockchains: [TokenItem]) {
        self.userWalletId = userWalletId
        self.defaultBlockchains = defaultBlockchains
    }

    func makeDefaultAccount(defaultTokensOverride: [StoredCryptoAccount.Token]) -> StoredCryptoAccount {
        let config = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let tokens = defaultTokensOverride.nilIfEmpty ?? StoredEntryConverter.convertToStoredEntries(enrichedDefaultBlockchains)

        return StoredCryptoAccount(config: config, tokenListAppearance: .default, tokens: tokens)
    }
}
