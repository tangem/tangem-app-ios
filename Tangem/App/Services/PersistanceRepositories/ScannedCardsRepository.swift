//
//  ScannedCardsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class ScannedCardsRepository {
    private(set) var cards: [String: SavedCard] = [:]
    private let storage: PersistentStorage
    private var storageKey: PersistentStorageKey { .cards }
    
    init(storage: PersistentStorage) {
        self.storage = storage
        fetch()
    }
    
    func add(_ cardInfo: CardInfo) {
        cards[cardInfo.card.cardId] = .savedCard(from: cardInfo)
        save()
    }
    
    private func save() {
        try? storage.store(value: cards, for: storageKey)
    }
    
    private func fetch() {
        cards = (try? storage.value(for: storageKey)) ?? [:]
    }
}
