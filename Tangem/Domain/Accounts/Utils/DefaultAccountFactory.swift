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

    func makeDefaultAccount(
        defaultTokensOverride: [StoredCryptoAccount.Token],
        defaultGroupingOverride: StoredCryptoAccount.Grouping?,
        defaultSortingOverride: StoredCryptoAccount.Sorting?
    ) -> StoredCryptoAccount {
        let config = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let tokens = defaultTokensOverride.nilIfEmpty ?? StoredEntryConverter.convertToStoredEntries(enrichedDefaultBlockchains)
        let appearance = CryptoAccountPersistentConfig.TokenListAppearance(
            grouping: defaultGroupingOverride ?? CryptoAccountPersistentConfig.TokenListAppearance.default.grouping,
            sorting: defaultSortingOverride ?? CryptoAccountPersistentConfig.TokenListAppearance.default.sorting
        )

        return StoredCryptoAccount(config: config, tokenListAppearance: appearance, tokens: tokens)
    }
}
