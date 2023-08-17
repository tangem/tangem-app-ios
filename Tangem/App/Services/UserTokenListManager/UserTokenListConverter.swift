//
//  UserTokenListConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain

struct UserTokenListConverter {
    private let supportedBlockchains: Set<Blockchain>

    init(
        supportedBlockchains: Set<Blockchain>
    ) {
        self.supportedBlockchains = supportedBlockchains
    }

    func mapToTokens(entries: [StorageEntry.V3.Entry]) -> [UserTokenList.Token] {
        return entries.map { entry in
            return UserTokenList.Token(
                id: entry.id,
                networkId: entry.networkId,
                name: entry.name,
                symbol: entry.symbol,
                decimals: entry.decimals,
                derivationPath: entry.blockchainNetwork.derivationPath,
                contractAddress: entry.contractAddress
            )
        }
    }

    func mapToEntries(list: UserTokenList) -> [StorageEntry.V3.Entry] {
        return list.tokens.compactMap { token -> StorageEntry.V3.Entry? in
            guard let blockchain = supportedBlockchains[token.networkId] else {
                return nil
            }

            let blockchainNetwork = StorageEntry.V3.BlockchainNetwork(blockchain, derivationPath: token.derivationPath)

            return StorageEntry.V3.Entry(
                id: token.id,
                networkId: token.networkId,
                name: token.name,
                symbol: token.symbol,
                decimals: token.decimals,
                blockchainNetwork: blockchainNetwork,
                contractAddress: token.contractAddress
            )
        }
    }
}
