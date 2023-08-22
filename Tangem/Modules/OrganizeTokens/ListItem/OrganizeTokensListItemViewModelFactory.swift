//
//  OrganizeTokensListItemViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensListItemViewModelFactory {
    private let tokenIconInfoBuilder: TokenIconInfoBuilder

    init(
        tokenIconInfoBuilder: TokenIconInfoBuilder
    ) {
        self.tokenIconInfoBuilder = tokenIconInfoBuilder
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
        case .withoutDerivation(let userToken, let blockchainNetwork, let walletModelId):
            return makeListItemViewModel(
                userToken: userToken,
                blockchainNetwork: blockchainNetwork,
                walletModelId: walletModelId,
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
        blockchainNetwork: BlockchainNetwork,
        walletModelId: WalletModel.ID,
        isDraggable: Bool,
        inGroupedSection: Bool
    ) -> OrganizeTokensListItemViewModel {
        let converter = StorageEntriesConverter()

        let identifier = OrganizeTokensListItemViewModel.Identifier(
            walletModelId: walletModelId,
            inGroupedSection: inGroupedSection
        )

        if let token = converter.convertToToken(userToken) {
            let tokenIcon = tokenIconInfoBuilder.build(
                for: .token(value: token),
                in: blockchainNetwork.blockchain
            )
            return OrganizeTokensListItemViewModel(
                id: identifier,
                tokenIcon: tokenIcon,
                balance: .noData,
                hasDerivation: false,
                isTestnet: blockchainNetwork.blockchain.isTestnet,
                isNetworkUnreachable: false,
                isDraggable: isDraggable
            )
        }

        let tokenIcon = tokenIconInfoBuilder.build(
            for: .coin,
            in: blockchainNetwork.blockchain
        )

        return OrganizeTokensListItemViewModel(
            id: identifier,
            tokenIcon: tokenIcon,
            balance: .noData,
            hasDerivation: false,
            isTestnet: blockchainNetwork.blockchain.isTestnet,
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
