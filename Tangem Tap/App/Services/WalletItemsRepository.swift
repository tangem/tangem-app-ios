//
//  WalletItemsService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class WalletItemsRepository {
    lazy var supportedWalletItems = SupportedWalletItems()
    
    private(set) var walletItems: [TokenItem] = []
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
    
    func append(_ walletItem: TokenItem) {
        walletItems.append(walletItem)
        save()
    }
    
    func append(_ walletItems: [TokenItem]) {
        self.walletItems.append(contentsOf: walletItems)
        save()
    }
    
    func remove(_ walletItem: TokenItem) {
        walletItems.remove(walletItem)
        save()
    }
    
    private func save() {
        try? persistanceStorage.store(value: walletItems, for: storageKey)
    }
    
    private func fetch() {
        walletItems = (try? persistanceStorage.value(for: storageKey)) ?? []
    }
}
