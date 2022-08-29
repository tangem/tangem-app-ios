//
//  LegacyCardMigrator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Temporary solution to migrate default tokens of old miltiwallet cards to TokenItemsRepository. Remove at Q3-Q4'22
class LegacyCardMigrator {
    private let cardId: String
    private let embeddedEntry: StorageEntry
    private let tokenItemsRepository: TokenItemsRepository

    init?(cardId: String, config: UserWalletConfig) {
        guard config.hasFeature(.multiCurrency) else {
            return nil
        }

        // Check if we have anything to migrate. It's impossible to get default token without default blockchain
        guard let embeddedEntry = config.embeddedBlockchain else {
            return nil
        }
        
        self.cardId = cardId
        self.embeddedEntry = embeddedEntry

        // Only in this case we work with the repository for cardId
        self.tokenItemsRepository = CommonTokenItemsRepository(key: cardId)
    }

    // Save default blockchain and token to main tokens repo.
    func migrateIfNeeded() {
        // Migrate only once.
        guard !AppSettings.shared.migratedCardsWithDefaultTokens.contains(cardId) else {
            return
        }

        var entries = tokenItemsRepository.getItems()
        entries.insert(embeddedEntry, at: 0)

        // We need to preserve order of token items
        tokenItemsRepository.removeAll()
        tokenItemsRepository.append(entries)

        AppSettings.shared.migratedCardsWithDefaultTokens.append(cardId)
    }
}
