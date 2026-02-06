//
//  CommonDefaultAccountFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CommonDefaultAccountFactory: DefaultAccountFactory {
    private let userWalletId: UserWalletId
    private let defaultBlockchains: [TokenItem]
    private let persistentStorage: CryptoAccountsPersistentStorage

    private var enrichedDefaultBlockchains: [TokenItem] {
        TokenItemsEnricher.enrichedWithBlockchainNetworksIfNeeded(defaultBlockchains)
    }

    init(
        userWalletId: UserWalletId,
        defaultBlockchains: [TokenItem],
        persistentStorage: CryptoAccountsPersistentStorage
    ) {
        self.userWalletId = userWalletId
        self.defaultBlockchains = defaultBlockchains
        self.persistentStorage = persistentStorage
    }

    func makeDefaultAccount(
        defaultTokensOverride: [StoredCryptoAccount.Token]?,
        defaultGroupingOverride: StoredCryptoAccount.Grouping?,
        defaultSortingOverride: StoredCryptoAccount.Sorting?
    ) -> StoredCryptoAccount {
        let config = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let tokens = defaultTokensOverride ?? StoredEntryConverter.convertToStoredEntries(enrichedDefaultBlockchains)
        let appearance = CryptoAccountPersistentConfig.TokenListAppearance(
            grouping: defaultGroupingOverride ?? CryptoAccountPersistentConfig.TokenListAppearance.default.grouping,
            sorting: defaultSortingOverride ?? CryptoAccountPersistentConfig.TokenListAppearance.default.sorting
        )

        return StoredCryptoAccount(config: config, tokenListAppearance: appearance, tokens: tokens)
    }

    func makeDefaultAccountPreferringExisting(
        defaultTokensOverride: [StoredCryptoAccount.Token]?,
        defaultGroupingOverride: StoredCryptoAccount.Grouping?,
        defaultSortingOverride: StoredCryptoAccount.Sorting?
    ) -> StoredCryptoAccount {
        // If the wallet was created offline due to network issues and then the user added some tokens to it
        // - we use this existing default account. Otherwise - we create a new default account with default tokens.
        if let existingDefaultAccount = persistentStorage
            .getList()
            .first(where: { $0.derivationIndex == AccountModelUtils.mainAccountDerivationIndex && $0.tokens.isNotEmpty }) {
            return existingDefaultAccount
        }

        // In some rare edge cases, when a wallet has already been created and used on a previous app version
        // (w/o accounts support) and this wallet has an empty token list, default tokens from
        // `CommonDefaultAccountFactory.defaultBlockchains` (i.e. `UserWalletConfig.defaultBlockchains`) will be added
        // to the newly created account. We consider this behavior acceptable (mirrors the Android implementation).
        return makeDefaultAccount(
            defaultTokensOverride: defaultTokensOverride,
            defaultGroupingOverride: defaultGroupingOverride,
            defaultSortingOverride: defaultSortingOverride
        )
    }
}
