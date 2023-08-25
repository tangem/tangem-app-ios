//
//  StorageEntryConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

struct StorageEntryConverter {
    // MARK: - StoredUserTokenList to StorageEntry

    func convertToStorageEntries(_ userTokens: [StoredUserTokenList.Entry]) -> [StorageEntry] {
        let userTokensGroupedByBlockchainNetworks = Dictionary(grouping: userTokens, by: \.blockchainNetwork)

        let blockchainNetworks = userTokens
            .unique(by: \.blockchainNetwork)
            .map(\.blockchainNetwork)

        return blockchainNetworks.reduce(into: []) { partialResult, blockchainNetwork in
            let userTokens = userTokensGroupedByBlockchainNetworks[blockchainNetwork] ?? []
            let tokens = userTokens.compactMap(convertToToken(_:))
            let storageEntry = StorageEntry(blockchainNetwork: blockchainNetwork, tokens: tokens)
            partialResult.append(storageEntry)
        }
    }

    func convertToToken(_ userToken: StoredUserTokenList.Entry) -> Token? {
        guard let contractAddress = userToken.contractAddress else { return nil }

        return Token(
            name: userToken.name,
            symbol: userToken.symbol,
            contractAddress: contractAddress,
            decimalCount: userToken.decimalCount,
            id: userToken.id
        )
    }

    // MARK: - StorageEntry to StoredUserTokenList

    func convertToStoredUserTokens(_ entries: [StorageEntry]) -> [StoredUserTokenList.Entry] {
        return entries.reduce(into: []) { partialResult, entry in
            let blockchainNetwork = entry.blockchainNetwork
            let blockchain = blockchainNetwork.blockchain

            partialResult.append(
                StoredUserTokenList.Entry(
                    id: blockchain.coinId,
                    name: blockchain.displayName, // [REDACTED_TODO_COMMENT]
                    symbol: blockchain.currencySymbol,
                    decimalCount: blockchain.decimalCount,
                    blockchainNetwork: blockchainNetwork,
                    contractAddress: nil
                )
            )

            partialResult += entry.tokens.map { convertToStoredUserToken($0, in: blockchainNetwork) }
        }
    }

    func convertToStoredUserToken(
        _ token: Token,
        in blockchainNetwork: BlockchainNetwork
    ) -> StoredUserTokenList.Entry {
        return StoredUserTokenList.Entry(
            id: token.id,
            name: token.name,
            symbol: token.symbol,
            decimalCount: token.decimalCount,
            blockchainNetwork: blockchainNetwork,
            contractAddress: token.contractAddress
        )
    }
}
