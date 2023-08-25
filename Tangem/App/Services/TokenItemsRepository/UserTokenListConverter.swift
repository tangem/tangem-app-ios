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

    // MARK: - Stored to Remote

    func convertStoredToRemote(_ storedUserTokenList: StoredUserTokenList) -> UserTokenList {
        let tokens = storedUserTokenList
            .entries
            .compactMap { entry in
                let blockchainNetwork = entry.blockchainNetwork
                let id = entry.isToken ? entry.id : blockchainNetwork.blockchain.coinId

                return UserTokenList.Token(
                    id: id,
                    networkId: blockchainNetwork.blockchain.networkId,
                    name: entry.name,
                    symbol: entry.symbol,
                    decimals: entry.decimalCount,
                    derivationPath: blockchainNetwork.derivationPath,
                    contractAddress: entry.contractAddress
                )
            }
            .unique() /// Additional uniqueness check for remote tokens (replicates old behavior)

        return UserTokenList(
            tokens: tokens,
            group: convertToGroupType(groupingOption: storedUserTokenList.grouping),
            sort: convertToSortType(sortingOption: storedUserTokenList.sorting)
        )
    }

    private func convertToGroupType(
        groupingOption: StoredUserTokenList.Grouping
    ) -> UserTokenList.GroupType {
        switch groupingOption {
        case .none:
            return .none
        case .byBlockchainNetwork:
            return .network
        }
    }

    private func convertToSortType(
        sortingOption: StoredUserTokenList.Sorting
    ) -> UserTokenList.SortType {
        switch sortingOption {
        case .manual:
            return .manual
        case .byBalance:
            return .balance
        }
    }

    // MARK: - Remote to Stored

    func convertRemoteToStored(_ remoteUserTokenList: UserTokenList) -> StoredUserTokenList {
        var addedTokens: [BlockchainNetwork: Set<String>] = [:]

        let entries = remoteUserTokenList
            .tokens
            .compactMap { token -> StoredUserTokenList.Entry? in
                guard let blockchain = supportedBlockchains[token.networkId] else {
                    return nil
                }

                let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: token.derivationPath)

                let token = StoredUserTokenList.Entry(
                    id: token.id,
                    name: token.name,
                    symbol: token.symbol,
                    decimalCount: token.decimals,
                    blockchainNetwork: blockchainNetwork,
                    contractAddress: token.contractAddress
                )

                if let contractAddress = token.contractAddress {
                    /// Additional uniqueness check for remote tokens (replicates old behavior)
                    if addedTokens[blockchainNetwork, default: []].insert(contractAddress).inserted {
                        return token
                    }
                    return nil // Duplicate detected
                } else {
                    return token
                }
            }

        return StoredUserTokenList(
            entries: entries,
            grouping: convertToGroupingOption(groupType: remoteUserTokenList.group),
            sorting: convertToSortingOption(sortType: remoteUserTokenList.sort)
        )
    }

    private func convertToGroupingOption(
        groupType: UserTokenList.GroupType
    ) -> StoredUserTokenList.Grouping {
        switch groupType {
        case .none:
            return .none
        case .network:
            return .byBlockchainNetwork
        }
    }

    private func convertToSortingOption(
        sortType: UserTokenList.SortType
    ) -> StoredUserTokenList.Sorting {
        switch sortType {
        case .manual:
            return .manual
        case .balance:
            return .byBalance
        }
    }
}
