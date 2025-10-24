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
        let tokens: [StoredCryptoAccount.Token] = defaultBlockchains.map { tokenItem in
            StoredCryptoAccount.Token(
                id: tokenItem.id,
                name: tokenItem.name,
                symbol: tokenItem.currencySymbol,
                decimalCount: tokenItem.decimalCount,
                blockchainNetwork: .known(blockchainNetwork: tokenItem.blockchainNetwork),
                contractAddress: tokenItem.contractAddress
            )
        }

        return StoredCryptoAccount(config: config, tokens: tokens)
    }
}
