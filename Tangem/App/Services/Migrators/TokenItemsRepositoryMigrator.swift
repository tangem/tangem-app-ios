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
        guard !AppSettings.shared.migratedTokenRepositoryOnWalletId else {
            print("TokenRepository already has been migrated on user wallet id")
            return
        }

        let oldRepository = CommonTokenItemsRepository(key: cardId)
        let oldEntries = CommonTokenItemsRepository(key: cardId).getItems()
        oldRepository.removeAll()

        // Save a old entries in new repository
        let newRepository = CommonTokenItemsRepository(key: cardId)
        newRepository.update(oldEntries)
        AppSettings.shared.migratedTokenRepositoryOnWalletId = true
    }
}
