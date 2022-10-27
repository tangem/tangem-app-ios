//
//  TokenItemsRepositoryMigrator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemSdk.Card

struct TokenItemsRepositoryMigrator {
    private let cardId: String
    private let userWalletId: Data
    private let isHDWalletAllowed: Bool

    init(card: Card, userWalletId: Data) {
        self.cardId = card.cardId
        self.userWalletId = userWalletId
        self.isHDWalletAllowed = card.settings.isHDWalletAllowed
    }

    func migrate() {
        let oldRepository = CommonTokenItemsRepository(key: cardId)
        var oldEntries = oldRepository.getItems()

        guard !oldEntries.isEmpty else { return }

        if !isHDWalletAllowed {
            // Remove derivationPath if the card not supported HDWallet
            oldEntries = oldEntries.map {
                let network = BlockchainNetwork($0.blockchainNetwork.blockchain)
                return StorageEntry(blockchainNetwork: network, tokens: $0.tokens)
            }
        }

        // Save a old entries in new repository
        let newRepository = CommonTokenItemsRepository(key: userWalletId.hexString)
        newRepository.append(oldEntries)

        oldRepository.removeAll()
        print("TokenRepository for cardId: \(cardId) successfully migrates to userWalletId: \(userWalletId)")
    }
}
