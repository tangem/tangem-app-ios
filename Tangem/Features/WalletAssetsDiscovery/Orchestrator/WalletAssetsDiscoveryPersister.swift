//
//  WalletAssetsDiscoveryPersister.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol WalletAssetsDiscoveryPersister {
    func syncDiscoveredTokensWithAccounts(
        discoveredTokens: [TokenItem],
        accountModelsManager: AccountModelsManager
    ) async
}
