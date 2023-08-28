//
//  OrganizeTokensSectionsAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

/// Placed in a separate module because it is used by both 'Main' and 'Organize Tokens' modules
final class OrganizeTokensSectionsAdapter {
    typealias Section = SectionModel<SectionType, SectionItem>
    typealias UserToken = StoredUserTokenList.Entry
    typealias GroupingOption = UserTokensReorderingOptions.Grouping
    typealias SortingOption = UserTokensReorderingOptions.Sorting

    enum SectionType {
        case plain
        case group(by: BlockchainNetwork)
    }

    enum SectionItem {
        /// `Default` means `coin/token with derivation`,  unlike `withoutDerivation` case.
        case `default`(WalletModel)
        case withoutDerivation(OrganizeTokensSectionsAdapter.UserToken)
    }

    private let userTokenListManager: UserTokenListManager
    private let organizeTokensOptionsProviding: OrganizeTokensOptionsProviding

    init(
        userTokenListManager: UserTokenListManager,
        organizeTokensOptionsProviding: OrganizeTokensOptionsProviding
    ) {
        self.userTokenListManager = userTokenListManager
        self.organizeTokensOptionsProviding = organizeTokensOptionsProviding
    }

    func organizedSections(
        from walletModels: some Publisher<[WalletModel], Never>,
        on workingQueue: DispatchQueue
    ) -> some Publisher<[Section], Never> {
        return walletModels
            .combineLatest(
                userTokenListManager.userTokensListPublisher,
                organizeTokensOptionsProviding.groupingOption,
                organizeTokensOptionsProviding.sortingOption
            )
            .receive(on: workingQueue)
            .withWeakCaptureOf(self)
            .map { input in
                let (adapter, (walletModels, userTokensList, groupingOption, sortingOption)) = input
                return adapter.makeSections(
                    walletModels: walletModels,
                    userTokens: userTokensList.entries,
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
        let walletModelsKeyedByIds = walletModels
            .keyedFirst(by: \.id)

        let blockchainNetworksFromWalletModels = walletModels
            .map(\.blockchainNetwork)
            .toSet()

        let sectionItems: [SectionItem] = userTokens.compactMap { userToken in
            if blockchainNetworksFromWalletModels.contains(userToken.blockchainNetwork) {
                // Most likely we have wallet model (and derivation too) for this entry
                return walletModelsKeyedByIds[userToken.walletModelId].map { .default($0) }
            } else {
                // Section item for entry without derivation (yet)
                return .withoutDerivation(userToken)
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
        case .dragAndDrop:
            // Keeping existing sort order
            return sectionItems
        case .byBalance:
            // The underlying sorting algorithm is guaranteed to be stable in Swift 5.0 and above
            // For cases when both lhs and rhs values are w/o derivation we also maintain a stable order of such elements
            return sectionItems.sorted { lhs, rhs in
                switch (lhs, rhs) {
                case (.default, .withoutDerivation):
                    return true
                case (.withoutDerivation, .default), (.withoutDerivation, .withoutDerivation):
                    return false
                case (.default(let lhs), .default(let rhs)):
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

private extension OrganizeTokensSectionsAdapter.SectionItem {
    var blockchainNetwork: BlockchainNetwork {
        switch self {
        case .default(let walletModel):
            return walletModel.blockchainNetwork
        case .withoutDerivation(let userToken):
            return userToken.blockchainNetwork
        }
    }
}
