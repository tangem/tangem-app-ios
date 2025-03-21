//
//  TokenSectionsAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

/// Placed in a separate module because it is used by both 'Main' and 'Organize Tokens' modules
final class TokenSectionsAdapter {
    typealias Section = SectionModel<SectionType, SectionItem>
    typealias UserToken = StoredUserTokenList.Entry
    typealias GroupingOption = UserTokensReorderingOptions.Grouping
    typealias SortingOption = UserTokensReorderingOptions.Sorting
    typealias SectionItem = TokenItemType

    enum SectionType {
        case plain
        case group(by: BlockchainNetwork)
    }

    private let userTokenListManager: UserTokenListManager
    private let optionsProviding: OrganizeTokensOptionsProviding

    private let preservesLastSortedOrderOnSwitchToDragAndDrop: Bool
    private var cachedOrderedWalletModelIdsForPlainSections: [WalletModelId.ID] = []
    private var cachedOrderedWalletModelIdsForGroupedSections: [WalletModelId.ID] = []

    init(
        userTokenListManager: UserTokenListManager,
        optionsProviding: OrganizeTokensOptionsProviding,
        preservesLastSortedOrderOnSwitchToDragAndDrop: Bool
    ) {
        self.userTokenListManager = userTokenListManager
        self.optionsProviding = optionsProviding
        self.preservesLastSortedOrderOnSwitchToDragAndDrop = preservesLastSortedOrderOnSwitchToDragAndDrop
    }

    func organizedSections(
        from walletModels: some Publisher<[WalletModel], Never>,
        on workingQueue: DispatchQueue
    ) -> some Publisher<[Section], Never> {
        return walletModels
            .combineLatest(
                userTokenListManager.userTokensListPublisher,
                optionsProviding.groupingOption,
                optionsProviding.sortingOption
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
        walletModels: [any WalletModel],
        userTokens: [UserToken],
        groupingOption: GroupingOption,
        sortingOption: SortingOption
    ) -> [Section] {
        let sectionItems = makeSectionItems(
            walletModels: walletModels,
            userTokens: userTokens,
            groupingOption: groupingOption,
            sortingOption: sortingOption
        )

        let sections: [Section]
        switch groupingOption {
        case .none:
            sections = makePlainSections(sectionItems: sectionItems, sortingOption: sortingOption)
        case .byBlockchainNetwork:
            sections = makeGroupedSections(sectionItems: sectionItems, sortingOption: sortingOption)
        }

        let sortedSections = self.sections(sections, sortedBy: sortingOption)
        updateCachedOrder(from: sortedSections, groupingOption: groupingOption, sortingOption: sortingOption)

        return sortedSections
    }

    private func makeGroupedSections(
        sectionItems: [SectionItem],
        sortingOption: SortingOption
    ) -> [Section] {
        let blockchainNetworksFromSectionItems = sectionItems.uniqueProperties(\.blockchainNetwork)
        let sectionItemsGroupedByBlockchainNetworks = sectionItems.grouped(by: \.blockchainNetwork)

        return blockchainNetworksFromSectionItems.compactMap { blockchainNetwork in
            guard let sectionItems = sectionItemsGroupedByBlockchainNetworks[blockchainNetwork] else {
                return nil
            }

            let sortedSectionItems = self.sectionItems(sectionItems, sortedBy: sortingOption)

            return Section(model: .group(by: blockchainNetwork), items: sortedSectionItems)
        }
    }

    private func makePlainSections(
        sectionItems: [SectionItem],
        sortingOption: SortingOption
    ) -> [Section] {
        let sortedSectionItems = self.sectionItems(sectionItems, sortedBy: sortingOption)

        return [Section(model: .plain, items: sortedSectionItems)]
    }

    private func makeSectionItems(
        walletModels: [any WalletModel],
        userTokens: [UserToken],
        groupingOption: GroupingOption,
        sortingOption: SortingOption
    ) -> [SectionItem] {
        let walletModelsKeyedByIds = walletModels.keyedFirst(by: \.id)
        let blockchainNetworksFromWalletModels = walletModels
            .map(\.tokenItem.blockchainNetwork)
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

        guard
            preservesLastSortedOrderOnSwitchToDragAndDrop,
            sortingOption == .dragAndDrop
        else {
            return sectionItems
        }

        let cachedOrderedWalletModelIds: [WalletModelId.ID]
        switch groupingOption {
        case .none:
            cachedOrderedWalletModelIds = cachedOrderedWalletModelIdsForPlainSections
        case .byBlockchainNetwork:
            cachedOrderedWalletModelIds = cachedOrderedWalletModelIdsForGroupedSections
        }

        return reorderedSectionItems(from: sectionItems, cachedOrderedWalletModelIds: cachedOrderedWalletModelIds)
    }

    private func reorderedSectionItems(
        from sectionItems: [SectionItem],
        cachedOrderedWalletModelIds: [WalletModelId.ID]
    ) -> [SectionItem] {
        guard !cachedOrderedWalletModelIds.isEmpty else {
            return sectionItems
        }

        var sectionItemsKeyedByIds = sectionItems.keyedFirst(by: \.walletModelId)
        var reorderedSectionItems = cachedOrderedWalletModelIds.compactMap { walletModelId in
            sectionItemsKeyedByIds.removeValue(forKey: walletModelId)
        }

        // We have several new and not previously known section items since the last cache
        // update in `cachedOrderedWalletModelIds`, appending them to the end of the list
        if !sectionItemsKeyedByIds.isEmpty {
            for sectionItem in sectionItems {
                if sectionItemsKeyedByIds[sectionItem.walletModelId] != nil {
                    reorderedSectionItems.append(sectionItem)
                }
            }
        }

        return reorderedSectionItems
    }

    private func sections(
        _ sections: [Section],
        sortedBy sortingOption: SortingOption
    ) -> [Section] {
        switch sortingOption {
        case .dragAndDrop:
            // Keeping existing sort order
            return sections
        case .byBalance:
            return sections.sorted { $0.totalFiatValue > $1.totalFiatValue }
        }
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
            let allWalletModels = sectionItems
                .compactMap(\.walletModel)

            // We don't sort section items by balance if some of them don't have balance information
            let hasWalletModelsWithoutBalanceInfo = allWalletModels
                .contains { $0.totalTokenBalanceProvider.balanceType.value == .none }

            if hasWalletModelsWithoutBalanceInfo {
                return sectionItems
            }

            // We don't sort section items by balance if some of them don't have quotes information
            // This rule doesn't apply to custom wallet models (with `canUseQuotes` == false),
            // because such wallet models can't have quotes
            let hasWalletModelsWithoutQuotesInfo = allWalletModels
                .filter { $0.canUseQuotes }
                .contains { $0.quote == nil }

            if hasWalletModelsWithoutQuotesInfo {
                return sectionItems
            }

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

    private func compareWalletModels(_ lhs: any WalletModel, _ rhs: any WalletModel) -> Bool {
        // Fiat balances that aren't loaded (e.g. due to network failures) fallback to zero
        let lFiatValue = lhs.fiatTotalTokenBalanceProvider.balanceType.value ?? .zero
        let rFiatValue = rhs.fiatTotalTokenBalanceProvider.balanceType.value ?? .zero

        return lFiatValue > rFiatValue
    }

    private func updateCachedOrder(
        from sections: [Section],
        groupingOption: GroupingOption,
        sortingOption: SortingOption
    ) {
        guard
            preservesLastSortedOrderOnSwitchToDragAndDrop,
            sortingOption == .byBalance
        else {
            return
        }

        let cachedOrderedWalletModelIds = sections.flatMap(\.walletModelIds)
        switch groupingOption {
        case .none:
            cachedOrderedWalletModelIdsForPlainSections = cachedOrderedWalletModelIds
        case .byBlockchainNetwork:
            cachedOrderedWalletModelIdsForGroupedSections = cachedOrderedWalletModelIds
        }
    }
}

// MARK: - Convenience extensions

extension TokenSectionsAdapter.SectionItem {
    var walletModel: (any WalletModel)? {
        switch self {
        case .default(let walletModel):
            return walletModel
        case .withoutDerivation:
            return nil
        }
    }

    var walletModelId: WalletModelId.ID {
        switch self {
        case .default(let walletModel):
            return walletModel.id.id
        case .withoutDerivation(let userToken):
            return userToken.walletModelId.id
        }
    }
}

private extension TokenSectionsAdapter.SectionItem {
    var blockchainNetwork: BlockchainNetwork {
        switch self {
        case .default(let walletModel):
            return walletModel.tokenItem.blockchainNetwork
        case .withoutDerivation(let userToken):
            return userToken.blockchainNetwork
        }
    }
}

private extension TokenSectionsAdapter.Section {
    var totalFiatValue: Decimal {
        return items.reduce(into: .zero) { partialResult, item in
            switch item {
            case .default(let walletModel):
                if let fiatValue = walletModel.fiatTotalTokenBalanceProvider.balanceType.value {
                    partialResult += fiatValue
                }
            case .withoutDerivation:
                break
            }
        }
    }

    var walletModelIds: [WalletModelId.ID] {
        return items.map(\.walletModelId)
    }
}
