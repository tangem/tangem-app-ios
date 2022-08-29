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
//        print(AppSettings.shared.migrationOnWalletIdTokenRepositoryCards)
        AppSettings.shared.migrationOnWalletIdTokenRepositoryCards.removeAll(where: { $0 == cardId })
        guard !AppSettings.shared.migrationOnWalletIdTokenRepositoryCards.contains(cardId) else {
            print("TokenRepository for cardId: \(cardId) already has been migrated on user wallet id")
            return
        }

        let oldRepository = CommonTokenItemsRepository(key: cardId)
        let oldEntries = oldRepository.getItems()
//        oldRepository.removeAll()

        // Save a old entries in new repository
        let newRepository = CommonTokenItemsRepository(key: userWalletId)
        newRepository.append(oldEntries)
        print("newRepository", newRepository.getItems())
        print("TokenRepository for cardId: \(cardId) successfully migrates to userWalletId: \(userWalletId)")
        AppSettings.shared.migrationOnWalletIdTokenRepositoryCards.append(cardId)
    }
}
