//
//  StorableEntriesConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum StorableEntriesConverter {
    static func convert(legacyStoredTokens: [StoredUserTokenList.Entry]) -> [StoredCryptoAccount.Token] {
        return legacyStoredTokens.map { entry in
            StoredCryptoAccount.Token(
                id: entry.id,
                name: entry.name,
                symbol: entry.symbol,
                decimalCount: entry.decimalCount,
                blockchainNetwork: .known(blockchainNetwork: entry.blockchainNetwork),
                contractAddress: entry.contractAddress
            )
        }
    }
}
