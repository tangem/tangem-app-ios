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
    private let userWalletId: Data

    init(cardId: String, userWalletId: Data) {
        self.cardId = cardId
        self.userWalletId = userWalletId
    }

    func migrate() {
        let oldRepository = CommonTokenItemsRepository(key: cardId)
        let oldEntries = oldRepository.getItems()

        guard !oldEntries.isEmpty else { return }

        // Save a old entries in new repository
        let newRepository = CommonTokenItemsRepository(key: userWalletId.hexString)
        newRepository.append(oldEntries)

        oldRepository.removeAll()
        print("TokenRepository for cardId: \(cardId) successfully migrates to userWalletId: \(userWalletId)")
    }
}
