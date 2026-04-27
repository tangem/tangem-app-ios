//
//  WalletTokenAutoSyncPersister.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol WalletTokenAutoSyncPersister {
    func syncDiscoveredTokensWithAccounts(
        discoveredTokens: [TokenItem],
        accountModelsManager: AccountModelsManager
    ) async
}
