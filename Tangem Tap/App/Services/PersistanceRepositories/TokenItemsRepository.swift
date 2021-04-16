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
    
    private(set) var items: Set<TokenItem> = []
    private let persistanceStorage: PersistentStorage
    private var cardId: String = ""
    private var storageKey: PersistentStorageKey { .wallets(cid: cardId) }
    private let lockQueue = DispatchQueue(label: "token_items_repo_queue")
    
    internal init(persistanceStorage: PersistentStorage) {
        self.persistanceStorage = persistanceStorage
    }
    
    deinit {
        print("TokenItemsRepository deinit")
    }
    
    func setCard(_ cardId: String) {
        self.cardId = cardId
        fetch()
    }
    
    func append(_ tokenItem: TokenItem) {
        lockQueue.sync {
            items.insert(tokenItem)
            save()
        }
    }
    
    func append(_ tokenItems: [TokenItem]) {
        lockQueue.sync {
            for token in tokenItems {
                items.insert(token)
            }
            save()
        }
    }
    
    func remove(_ tokenItem: TokenItem) {
        lockQueue.sync {
            items.remove(tokenItem)
            save()
        }
    }
    
    func removeAll() {
        lockQueue.sync {
            items = []
            save()
        }
    }
    
    func save() {
        try? persistanceStorage.store(value: items, for: storageKey)
    }
    
    func fetch() {
        lockQueue.sync {
            items = (try? persistanceStorage.value(for: storageKey)) ?? []
        }
    }
}
