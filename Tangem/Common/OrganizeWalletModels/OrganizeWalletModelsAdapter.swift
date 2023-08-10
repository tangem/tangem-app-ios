//
//  OrganizeWalletModelsAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct BlockchainSdk.Amount // [REDACTED_TODO_COMMENT]
import enum BlockchainSdk.Blockchain // [REDACTED_TODO_COMMENT]

final class OrganizeWalletModelsAdapter {
    typealias Section = OrganizeWalletModelsSection<SectionType>
    typealias UserToken = UserTokenList.Token // [REDACTED_TODO_COMMENT]
    typealias GroupingOption = OrganizeTokensOptions.Grouping
    typealias SortingOption = OrganizeTokensOptions.Sorting

    enum SectionType {
        case group(by: BlockchainNetwork)
        case plain
    }

    private let userTokenListManager: UserTokenListManager
    private let organizeTokensOptionsProviding: OrganizeTokensOptionsProviding
    private let organizeTokensOptionsEditing: OrganizeTokensOptionsEditing

    init(
        userTokenListManager: UserTokenListManager,
        organizeTokensOptionsProviding: OrganizeTokensOptionsProviding,
        organizeTokensOptionsEditing: OrganizeTokensOptionsEditing
    ) {
        self.userTokenListManager = userTokenListManager
        self.organizeTokensOptionsProviding = organizeTokensOptionsProviding
        self.organizeTokensOptionsEditing = organizeTokensOptionsEditing
    }

    func organizedWalletModels(
        from walletModels: some Publisher<[WalletModel], Never>,
        on workingQueue: DispatchQueue
    ) -> some Publisher<[Section], Never> {
        return walletModels
            .combineLatest(
                userTokenListManager.userTokenList.map(\.tokens),
                organizeTokensOptionsProviding.groupingOption,
                organizeTokensOptionsProviding.sortingOption
            )
            .receive(on: workingQueue)
            .map { walletModels, userTokens, groupingOption, sortingOption in
                return Self.makeSections(
                    walletModels: walletModels,
                    userTokens: userTokens,
                    groupingOption: groupingOption,
                    sortingOption: sortingOption
                )
            }
    }

    private static func makeSections(
        walletModels: [WalletModel],
        userTokens: [UserToken],
        groupingOption: GroupingOption,
        sortingOption: SortingOption
    ) -> [Section] {
        let walletModelsKeyedByID = walletModels
            .keyedFirst(by: \.id)

        switch groupingOption {
        case .byBlockchainNetwork:
            return makeGroupedSections(
                walletModelsKeyedByID: walletModelsKeyedByID,
                userTokens: userTokens,
                sortingOption: sortingOption
            )
        case .none:
            return makePlainSections(
                walletModelsKeyedByID: walletModelsKeyedByID,
                userTokens: userTokens,
                sortingOption: sortingOption
            )
        }
    }

    private static func makeGroupedSections(
        walletModelsKeyedByID: [WalletModel.ID: WalletModel],
        userTokens: [UserToken],
        sortingOption: SortingOption
    ) -> [Section] {
        let blockchainNetworks = userTokens
            .unique(by: \.blockchainNetwork)
            .compactMap(\.blockchainNetwork)

        let userTokensGroupedByBlockchainNetworks: [BlockchainNetwork: [UserToken]] = userTokens
            .reduce(into: [:]) { partialResult, element in
                guard let blockchainNetwork = element.blockchainNetwork else { return }

                partialResult[blockchainNetwork, default: []].append(element)
            }

        return blockchainNetworks.map { blockchainNetwork in
            let userTokensForBlockchainNetwork = userTokensGroupedByBlockchainNetworks[blockchainNetwork, default: []]
            let walletModelsForBlockchainNetwork = userTokensForBlockchainNetwork.compactMap { token -> WalletModel? in
                guard let walletModelID = token.walletModelID else { return nil }

                return walletModelsKeyedByID[walletModelID]
            }
            let sortedWalletModelsForBlockchainNetwork = self.walletModels(
                walletModelsForBlockchainNetwork,
                sortedBy: sortingOption
            )
            return Section(
                model: .group(by: blockchainNetwork),
                items: sortedWalletModelsForBlockchainNetwork
            )
        }
    }

    private static func makePlainSections(
        walletModelsKeyedByID: [WalletModel.ID: WalletModel],
        userTokens: [UserToken],
        sortingOption: SortingOption
    ) -> [Section] {
        let walletModels = userTokens.compactMap { token -> WalletModel? in
            guard let walletModelID = token.walletModelID else { return nil }

            return walletModelsKeyedByID[walletModelID]
        }
        let sortedWalletModels = self.walletModels(
            walletModels,
            sortedBy: sortingOption
        )

        return [
            Section(
                model: .plain,
                items: sortedWalletModels
            ),
        ]
    }

    private static func walletModels(
        _ walletModels: [WalletModel],
        sortedBy sortingOption: SortingOption
    ) -> [WalletModel] {
        switch sortingOption {
        case .dragAndDrop:
            // Keeping existing sort order
            return walletModels
        case .byBalance:
            // The underlying sorting algorithm is guaranteed to be stable in Swift 5.0 and above
            // For cases when both lhs and rhs values are nil we also maintain a stable order of such elements
            return walletModels.sorted { lhs, rhs in
                switch (lhs.fiatValue, rhs.fiatValue) {
                case (.some, .none):
                    return true
                case (.none, .some), (.none, .none):
                    return false
                case (.some(let lhsFiatValue), .some(let rhsFiatValue)):
                    return lhsFiatValue > rhsFiatValue
                }
            }
        }
    }
}

// MARK: - Convenience extensions

// [REDACTED_TODO_COMMENT]
private extension UserTokenList.Token {
    var blockchainNetwork: BlockchainNetwork? {
        guard let blockchain = Blockchain(from: networkId) else { return nil }

        return BlockchainNetwork(blockchain, derivationPath: derivationPath)
    }

    var walletModelID: WalletModel.ID? {
        guard let blockchainNetwork = blockchainNetwork else { return nil }

        return WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: amountType).id
    }

    private var amountType: Amount.AmountType {
        if let contractAddress = contractAddress {
            return .token(
                value: .init(
                    name: name,
                    symbol: symbol,
                    contractAddress: contractAddress,
                    decimalCount: decimals,
                    id: id
                )
            )
        } else {
            return .coin
        }
    }
}
