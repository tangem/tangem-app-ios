//
//  ScannedCardsRepository.swift
//  Tangem Tap
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
    
    func add(_ card: Card) {
        cards[card.cardId] = .savedCard(from: card)
        save()
    }
    
    private func save() {
        try? storage.store(value: cards, for: storageKey)
    }
    
    private func fetch() {
        if let cards: [String: Card] = try? storage.value(for: storageKey) {
            self.cards = cards.compactMapValues { .savedCard(from: $0) }
            save()
            return
        }
        cards = (try? storage.value(for: storageKey)) ?? [:]
    }
}
