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

    func makeDefaultAccountPreferringExisting(defaultTokensOverride: [StoredCryptoAccount.Token]) -> StoredCryptoAccount {
        // If the wallet was created offline due to network issues, we use this existing default account
        // Remote data (such as accounts and tokens) will be overwritten (by creating and uploading a new default account),
        // this is expected behavior
        if let existingDefaultAccount = persistentStorage
            .getList()
            .first(where: { $0.derivationIndex == AccountModelUtils.mainAccountDerivationIndex }) {
            return existingDefaultAccount
        }

        // In some rare edge cases, when a wallet has already been created and used on a previous app version
        // (w/o accounts support) and this wallet has an empty token list, default tokens from
        // `CommonDefaultAccountFactory.defaultBlockchains` (i.e. `UserWalletConfig.defaultBlockchains`) will be added
        // to the newly created account. We consider this behavior acceptable (mirrors the Android implementation).
        return makeDefaultAccount(defaultTokensOverride: defaultTokensOverride)
    }

    func makeDefaultAccount(defaultTokensOverride: [StoredCryptoAccount.Token]) -> StoredCryptoAccount {
        let config = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let tokens = defaultTokensOverride.nilIfEmpty ?? StoredEntryConverter.convertToStoredEntries(enrichedDefaultBlockchains)

        return StoredCryptoAccount(config: config, tokenListAppearance: .default, tokens: tokens)
    }
}
