//
//  LegacyStoredEntryConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS, deprecated: 100000.0, message: "For migration purposes only. Will be removed later ([REDACTED_INFO])")
enum LegacyStoredEntryConverter {
    static func convert(legacyStoredTokens: [StoredUserTokenList.Entry]) -> [StoredCryptoAccount.Token] {
        return legacyStoredTokens.map { entry in
            StoredCryptoAccount.Token(
                id: entry.id,
                name: entry.name,
                symbol: entry.symbol,
                decimalCount: entry.decimalCount,
                // By definition, all legacy tokens currently stored are known
                blockchainNetwork: .known(blockchainNetwork: entry.blockchainNetwork),
                contractAddress: entry.contractAddress
            )
        }
    }

    static func convert(
        legacyStoredTokenListToAppearance legacyStoredTokenList: StoredUserTokenList
    ) -> CryptoAccountPersistentConfig.TokenListAppearance {
        let grouping: StoredCryptoAccount.Grouping = switch legacyStoredTokenList.grouping {
        case .none: .none
        case .byBlockchainNetwork: .byBlockchainNetwork
        }

        let sorting: StoredCryptoAccount.Sorting = switch legacyStoredTokenList.sorting {
        case .manual: .manual
        case .byBalance: .byBalance
        }

        return CryptoAccountPersistentConfig.TokenListAppearance(
            grouping: grouping,
            sorting: sorting
        )
    }
}
