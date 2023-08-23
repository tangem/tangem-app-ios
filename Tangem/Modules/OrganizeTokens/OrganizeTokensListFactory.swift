//
//  OrganizeTokensListFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensListFactory {
    private let tokenIconInfoBuilder: TokenIconInfoBuilder

    init(
        tokenIconInfoBuilder: TokenIconInfoBuilder
    ) {
        self.tokenIconInfoBuilder = tokenIconInfoBuilder
    }

    func makeListSection(
        from sectionType: OrganizeTokensSectionsAdapter.SectionType,
        with itemViewModels: [OrganizeTokensListItemViewModel],
        atIndex index: Int
    ) -> OrganizeTokensListSection {
        switch sectionType {
        case .plain:
            // Plain sections use section indices (from `enumerated()`) as a stable identity, but in
            // reality we always have only one single plain section, so the identity doesn't matter here
            return OrganizeTokensListSection(
                model: .init(id: index, style: .invisible),
                items: itemViewModels
            )
        case .group(let blockchainNetwork):
            let title = Localization.walletNetworkGroupTitle(blockchainNetwork.blockchain.displayName)
            return OrganizeTokensListSection(
                model: .init(id: blockchainNetwork, style: .draggable(title: title)),
                items: itemViewModels
            )
        }
    }

    func makeListItemViewModel(
        sectionItem: OrganizeTokensSectionsAdapter.SectionItem,
        isDraggable: Bool,
        inGroupedSection: Bool
    ) -> OrganizeTokensListItemViewModel {
        switch sectionItem {
        case .default(let walletModel):
            return makeListItemViewModel(
                walletModel: walletModel,
                isDraggable: isDraggable,
                inGroupedSection: inGroupedSection
            )
        case .withoutDerivation(let userToken):
            return makeListItemViewModel(
                userToken: userToken,
                isDraggable: isDraggable,
                inGroupedSection: inGroupedSection
            )
        }
    }

    private func makeListItemViewModel(
        walletModel: WalletModel,
        isDraggable: Bool,
        inGroupedSection: Bool
    ) -> OrganizeTokensListItemViewModel {
        let identifier = OrganizeTokensListItemViewModel.Identifier(
            walletModelId: walletModel.id,
            inGroupedSection: inGroupedSection
        )
        let tokenIcon = tokenIconInfoBuilder.build(
            for: walletModel.amountType,
            in: walletModel.blockchainNetwork.blockchain
        )

        return OrganizeTokensListItemViewModel(
            id: identifier,
            tokenIcon: tokenIcon,
            balance: fiatBalance(for: walletModel),
            hasDerivation: true,
            isTestnet: walletModel.blockchainNetwork.blockchain.isTestnet,
            isNetworkUnreachable: walletModel.state.isBlockchainUnreachable,
            isDraggable: isDraggable
        )
    }

    private func makeListItemViewModel(
        userToken: OrganizeTokensSectionsAdapter.UserToken,
        isDraggable: Bool,
        inGroupedSection: Bool
    ) -> OrganizeTokensListItemViewModel {
        let converter = StorageEntriesConverter()
        let blockchain = userToken.blockchainNetwork.blockchain
        let isTestnet = blockchain.isTestnet
        let identifier = OrganizeTokensListItemViewModel.Identifier(
            walletModelId: userToken.walletModelId,
            inGroupedSection: inGroupedSection
        )

        if let token = converter.convertToToken(userToken) {
            let tokenIcon = tokenIconInfoBuilder.build(for: .token(value: token), in: blockchain)

            return OrganizeTokensListItemViewModel(
                id: identifier,
                tokenIcon: tokenIcon,
                balance: .noData,
                hasDerivation: false,
                isTestnet: isTestnet,
                isNetworkUnreachable: false,
                isDraggable: isDraggable
            )
        }

        let tokenIcon = tokenIconInfoBuilder.build(for: .coin, in: blockchain)

        return OrganizeTokensListItemViewModel(
            id: identifier,
            tokenIcon: tokenIcon,
            balance: .noData,
            hasDerivation: false,
            isTestnet: isTestnet,
            isNetworkUnreachable: false,
            isDraggable: isDraggable
        )
    }

    private func fiatBalance(for walletModel: WalletModel) -> LoadableTextView.State {
        guard !walletModel.rateFormatted.isEmpty else { return .noData }

        switch walletModel.state {
        case .created, .idle, .noAccount, .noDerivation:
            return .loaded(text: walletModel.fiatBalance)
        case .loading:
            return .loading
        case .failed:
            return .noData
        }
    }
}
