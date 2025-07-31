//
//  UserTokenListConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import enum BlockchainSdk.Blockchain

struct UserTokenListConverter {
    private let supportedBlockchains: Set<Blockchain>
    private weak var externalParametersProvider: UserTokenListExternalParametersProvider?

    init(supportedBlockchains: Set<Blockchain>, externalParametersProvider: UserTokenListExternalParametersProvider?) {
        self.supportedBlockchains = supportedBlockchains
        self.externalParametersProvider = externalParametersProvider
    }

    // MARK: - Stored to Remote

    func convertStoredToRemote(_ storedUserTokenList: StoredUserTokenList) -> UserTokenList {
        let walletModelAddresses = externalParametersProvider?.provideTokenListAddresses()

        let tokens = storedUserTokenList
            .entries
            .compactMap { entry in
                let network = entry.blockchainNetwork
                let id = entry.isToken ? entry.id : network.blockchain.coinId
                let name = entry.isToken ? entry.name : network.blockchain.coinDisplayName
                // Determine the addresses based on the notifyStatusValue.
                // If notifyStatusValue is true, fetch the addresses from the externalParametersProvider.
                // Otherwise, set addresses to an empty array.
                let addresses: [String]? = walletModelAddresses?[entry.walletModelId]

                return UserTokenList.Token(
                    id: id,
                    networkId: network.blockchain.networkId,
                    name: name,
                    symbol: entry.symbol,
                    decimals: entry.decimalCount,
                    derivationPath: network.derivationPath,
                    contractAddress: entry.contractAddress,
                    addresses: addresses
                )
            }
            .unique() // Additional uniqueness check for remote tokens (replicates old behavior)

        let notifyStatusValue = externalParametersProvider?.provideTokenListNotifyStatusValue()

        return UserTokenList(
            tokens: tokens,
            group: convertToGroupType(groupingOption: storedUserTokenList.grouping),
            sort: convertToSortType(sortingOption: storedUserTokenList.sorting),
            notifyStatus: notifyStatusValue
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

                let network = BlockchainNetwork(blockchain, derivationPath: token.derivationPath)

                let token = StoredUserTokenList.Entry(
                    id: token.id,
                    name: token.name,
                    symbol: token.symbol,
                    decimalCount: token.decimals,
                    blockchainNetwork: network,
                    contractAddress: token.contractAddress
                )

                if let contractAddress = token.contractAddress {
                    // Additional uniqueness check for remote tokens (replicates old behavior)
                    // Comparison logic here must match the implementation of `Equatable` for `BlockchainSdk.Token`
                    if addedTokens[network, default: []].insert(contractAddress.lowercased()).inserted {
                        return token
                    }
                    return nil // Duplicate token detected
                } else {
                    return token
                }
            }

        return StoredUserTokenList(
            entries: entries.unique(),
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
