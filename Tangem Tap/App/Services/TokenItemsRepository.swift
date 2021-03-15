//
//  TokenItemsRepository.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class TokenItemsRepository {
    lazy var supportedItems = SupportedTokenItems()
    
    private(set) var items: [TokenItem] = []
    private let persistanceStorage: PersistentStorage
    private var cardId: String = ""
    private var storageKey: PersistentStorageKey { .wallets(cid: cardId) }

    internal init(persistanceStorage: PersistentStorage) {
        self.persistanceStorage = persistanceStorage
    }
    
    func setCard(_ cardId: String) {
        self.cardId = cardId
        fetch()
    }
    
    func append(_ tokenItem: TokenItem) {
        items.append(tokenItem)
        save()
    }
    
    func append(_ tokenItems: [TokenItem]) {
        self.items.append(contentsOf: tokenItems)
        save()
    }
    
    func remove(_ tokenItem: TokenItem) {
        items.remove(tokenItem)
        save()
    }
    
    private func save() {
        try? persistanceStorage.store(value: items, for: storageKey)
    }
    
    private func fetch() {
        items = (try? persistanceStorage.value(for: storageKey)) ?? []
    }
}
