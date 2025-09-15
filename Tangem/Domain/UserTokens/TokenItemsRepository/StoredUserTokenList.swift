//
//  StoredUserTokenList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS, deprecated: 100000.0, message: "Superseded by 'StoredCryptoAccount', will be removed in the future")
struct StoredUserTokenList: Codable, Equatable {
    enum Grouping: Codable, Equatable {
        case none
        case byBlockchainNetwork
    }

    enum Sorting: Codable, Equatable {
        case manual
        case byBalance
    }

    struct Entry: Codable, Hashable {
        let id: String?
        let name: String
        let symbol: String
        let decimalCount: Int
        let blockchainNetwork: BlockchainNetwork
        let contractAddress: String?

        var coinId: String? {
            contractAddress == nil ? blockchainNetwork.blockchain.coinId : id
        }
    }

    let entries: [Entry]
    let grouping: Grouping
    let sorting: Sorting
}

// MARK: - Convenience extensions

extension StoredUserTokenList {
    static var empty: Self { Self(entries: [], grouping: .none, sorting: .manual) }
}

extension StoredUserTokenList.Entry {
    var isToken: Bool { contractAddress != nil }

    var isCustom: Bool { id == nil }

    var walletModelId: WalletModelId {
        let converter = StorageEntryConverter()

        if let token = converter.convertToToken(self) {
            return WalletModelId(tokenItem: .token(token, blockchainNetwork))
        }

        return WalletModelId(tokenItem: .blockchain(blockchainNetwork))
    }
}
