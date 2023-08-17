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

    // MARK: - Domain to DTO

    func convertToTokens(entries: [StorageEntry.V3.Entry]) -> [UserTokenList.Token] {
        return entries.map { entry in
            return UserTokenList.Token(
                id: entry.id,
                networkId: entry.blockchainNetwork.blockchain.networkId,
                name: entry.name,
                symbol: entry.symbol,
                decimals: entry.decimalCount,
                derivationPath: entry.blockchainNetwork.derivationPath,
                contractAddress: entry.contractAddress
            )
        }
    }

    func convertToGroupType(groupingOption: StorageEntry.V3.Grouping) -> UserTokenList.GroupType {
        switch groupingOption {
        case .none:
            return .none
        case .byBlockchainNetwork:
            return .network
        }
    }

    func convertToSortType(sortingOption: StorageEntry.V3.Sorting) -> UserTokenList.SortType {
        switch sortingOption {
        case .manual:
            return .manual
        case .byBalance:
            return .balance
        }
    }

    // MARK: - DTO to Domain

    func convertToEntries(list: UserTokenList) -> [StorageEntry.V3.Entry] {
        return list.tokens.compactMap { token -> StorageEntry.V3.Entry? in
            guard let blockchain = supportedBlockchains[token.networkId] else {
                return nil
            }

            let blockchainNetwork = StorageEntry.V3.BlockchainNetwork(blockchain, derivationPath: token.derivationPath)

            return StorageEntry.V3.Entry(
                id: token.id,
                name: token.name,
                symbol: token.symbol,
                decimalCount: token.decimals,
                blockchainNetwork: blockchainNetwork,
                contractAddress: token.contractAddress
            )
        }
    }

    func convertToGroupingOption(groupType: UserTokenList.GroupType) -> StorageEntry.V3.Grouping {
        switch groupType {
        case .none:
            return .none
        case .network:
            return .byBlockchainNetwork
        }
    }

    func convertToSortingOption(sortType: UserTokenList.SortType) -> StorageEntry.V3.Sorting {
        switch sortType {
        case .manual:
            return .manual
        case .balance:
            return .byBalance
        }
    }
}
