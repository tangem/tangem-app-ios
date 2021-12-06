//
//  TokenItemsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class TokenItemsRepository {
    private let persistanceStorage: PersistentStorage
    private let lockQueue = DispatchQueue(label: "token_items_repo_queue")
    
    internal init(persistanceStorage: PersistentStorage) {
        self.persistanceStorage = persistanceStorage
    }
    
    deinit {
        print("TokenItemsRepository deinit")
    }
    
    func append(_ tokenItem: TokenItem, for cardId: String) {
        lockQueue.sync {
            var items = fetch(for: cardId)
            
            if items.contains(tokenItem) {
                return
            }
            
            items.append(tokenItem)
            save(items, for: cardId)
        }
    }
    
    func append(_ tokenItems: [TokenItem], for cardId: String) {
        lockQueue.sync {
            var items = fetch(for: cardId)
            
            for tokenItem in tokenItems {
                if !items.contains(tokenItem) {
                    items.append(tokenItem)
                }
            }

            save(items, for: cardId)
        }
    }
    
    func remove(_ tokenItem: TokenItem, for cardId: String) {
        lockQueue.sync {
            var items = fetch(for: cardId)
            items.remove(tokenItem)
            save(items, for: cardId)
        }
    }
    
    func removeAll(for cardId: String) {
        lockQueue.sync {
            save([], for: cardId)
        }
    }
    
    func getItems(for cardId: String) -> [TokenItem] {
        lockQueue.sync {
            fetch(for: cardId)
        }
    }
    
    private func fetch(for cardId: String) -> [TokenItem] {
        return (try? persistanceStorage.value(for: .wallets(cid: cardId))) ?? []
    }
    
    private func save(_ items: [TokenItem], for cardId: String) {
        try? persistanceStorage.store(value: items, for: .wallets(cid: cardId))
    }
}
