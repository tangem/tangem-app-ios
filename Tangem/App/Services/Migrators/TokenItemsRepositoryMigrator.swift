//
//  TokenItemsRepositoryMigrator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TokenItemsRepositoryMigrator {
    private let cardId: String
    private let userWalletId: String

    init(cardId: String, userWalletId: String) {
        self.cardId = cardId
        self.userWalletId = userWalletId
    }

    func migrate() {
        let oldRepository = CommonTokenItemsRepository(key: cardId)
        let oldEntries = oldRepository.getItems()

        // Save a old entries in new repository
        let newRepository = CommonTokenItemsRepository(key: userWalletId)
        newRepository.append(oldEntries)

        oldRepository.removeAll()
        print("TokenRepository for cardId: \(cardId) successfully migrates to userWalletId: \(userWalletId)")
    }
}
