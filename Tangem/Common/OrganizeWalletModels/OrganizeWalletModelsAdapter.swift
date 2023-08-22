//
//  OrganizeWalletModelsAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class OrganizeWalletModelsAdapter {
    typealias Section = OrganizeWalletModelsSection<SectionType, SectionItem>
    typealias UserToken = StorageEntry.V3.Entry
    typealias GroupingOption = OrganizeTokensOptions.Grouping
    typealias SortingOption = OrganizeTokensOptions.Sorting

    enum SectionType {
        case group(by: BlockchainNetwork)
        case plain
    }

    enum SectionItem {
        case complete(WalletModel)
        case withoutDerivation(OrganizeWalletModelsAdapter.UserToken, BlockchainNetwork, WalletModel.ID)
    }

    private let userTokenListManager: UserTokenListManager
    private let walletModelComponentsBuilder: WalletModelComponentsBuilder
    private let organizeTokensOptionsProviding: OrganizeTokensOptionsProviding

    init(
        userTokenListManager: UserTokenListManager,
        walletModelComponentsBuilder: WalletModelComponentsBuilder,
        organizeTokensOptionsProviding: OrganizeTokensOptionsProviding
    ) {
        self.userTokenListManager = userTokenListManager
        self.walletModelComponentsBuilder = walletModelComponentsBuilder
        self.organizeTokensOptionsProviding = organizeTokensOptionsProviding
    }

    func organizedWalletModels(
        from walletModels: some Publisher<[WalletModel], Never>,
        on workingQueue: DispatchQueue
    ) -> some Publisher<[Section], Never> {
        return walletModels
            .combineLatest(
                userTokenListManager.userTokensPublisher,
                organizeTokensOptionsProviding.groupingOption,
                organizeTokensOptionsProviding.sortingOption
            )
            .receive(on: workingQueue)
            .withWeakCaptureOf(self)
            .map { input in
                let (adapter, (walletModels, userTokens, groupingOption, sortingOption)) = input
                return adapter.makeSections(
                    walletModels: walletModels,
                    userTokens: userTokens,
                    groupingOption: groupingOption,
                    sortingOption: sortingOption
                )
            }
    }

    private func makeSections(
        walletModels: [WalletModel],
        userTokens: [UserToken],
        groupingOption: GroupingOption,
        sortingOption: SortingOption
    ) -> [Section] {
        let walletModelsKeyedByIDs = walletModels
            .keyedFirst(by: \.id)

        let blockchainNetworksFromWalletModels = walletModelsKeyedByIDs
            .values
            .unique(by: \.blockchainNetwork)
            .map(\.blockchainNetwork)
            .toSet()

        let sectionItems: [SectionItem] = userTokens.compactMap { userToken in
            guard
                let blockchainNetwork = walletModelComponentsBuilder.buildBlockchainNetwork(from: userToken),
                let walletModelID = walletModelComponentsBuilder.buildWalletModelID(from: userToken)
            else {
                return nil
            }

            if blockchainNetworksFromWalletModels.contains(blockchainNetwork) {
                // Most likely we have wallet model (and derivation too) for this entry
                guard let walletModel = walletModelsKeyedByIDs[walletModelID] else { return nil }

                return .complete(walletModel)
            } else {
                // Section item for entry without derivation (yet)
                return .withoutDerivation(userToken, blockchainNetwork, walletModelID)
            }
        }

        switch groupingOption {
        case .byBlockchainNetwork:
            return makeGroupedSections(sectionItems: sectionItems, sortingOption: sortingOption)
        case .none:
            return makePlainSections(sectionItems: sectionItems, sortingOption: sortingOption)
        }
    }

    private func makeGroupedSections(
        sectionItems: [SectionItem],
        sortingOption: SortingOption
    ) -> [Section] {
        let blockchainNetworksFromSectionItems = sectionItems
            .map(\.blockchainNetwork)
            .unique()

        let sectionItemsGroupedByBlockchainNetworks = Dictionary(grouping: sectionItems, by: \.blockchainNetwork)

        return blockchainNetworksFromSectionItems.compactMap { blockchainNetwork in
            guard let sectionItems = sectionItemsGroupedByBlockchainNetworks[blockchainNetwork] else {
                return nil
            }

            let sortedSectionItems = self.sectionItems(sectionItems, sortedBy: sortingOption)

            return Section(
                model: .group(by: blockchainNetwork),
                items: sortedSectionItems
            )
        }
    }

    private func makePlainSections(
        sectionItems: [SectionItem],
        sortingOption: SortingOption
    ) -> [Section] {
        let sortedSectionItems = self.sectionItems(sectionItems, sortedBy: sortingOption)

        return [
            Section(
                model: .plain,
                items: sortedSectionItems
            ),
        ]
    }

    private func sectionItems(
        _ sectionItems: [SectionItem],
        sortedBy sortingOption: SortingOption
    ) -> [SectionItem] {
        switch sortingOption {
        case .manual:
            // Keeping existing sort order
            return sectionItems
        case .byBalance:
            // The underlying sorting algorithm is guaranteed to be stable in Swift 5.0 and above
            // For cases when both lhs and rhs values are w/o derivation we also maintain a stable order of such elements
            return sectionItems.sorted { lhs, rhs in
                switch (lhs, rhs) {
                case (.complete, .withoutDerivation):
                    return true
                case (.withoutDerivation, .complete),  (.withoutDerivation, .withoutDerivation):
                    return false
                case (.complete(let lhs), .complete(let rhs)):
                    return compareWalletModels(lhs, rhs)
                }
            }
        }
    }

    private func compareWalletModels(_ lhs: WalletModel, _ rhs: WalletModel) -> Bool {
        // For cases when both lhs and rhs values are nil we also maintain a stable order of such elements
        switch (lhs.fiatValue, rhs.fiatValue) {
        case (.some, .none):
            return true
        case (.none, .some), (.none, .none):
            return false
        case (.some(let lFiatValue), .some(let rFiatValue)):
            return lFiatValue > rFiatValue
        }
    }
}

// MARK: - Convenience extensions

private extension OrganizeWalletModelsAdapter.SectionItem {
    var blockchainNetwork: BlockchainNetwork {
        switch self {
        case .complete(let walletModel):
            return walletModel.blockchainNetwork
        case .withoutDerivation(_, let blockchainNetwork, _):
            return blockchainNetwork
        }
    }
}
