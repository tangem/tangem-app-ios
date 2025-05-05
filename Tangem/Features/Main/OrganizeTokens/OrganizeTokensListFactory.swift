//
//  OrganizeTokensListFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import struct BlockchainSdk.Token
import TangemUI

struct OrganizeTokensListFactory {
    private let tokenIconInfoBuilder: TokenIconInfoBuilder

    init(
        tokenIconInfoBuilder: TokenIconInfoBuilder
    ) {
        self.tokenIconInfoBuilder = tokenIconInfoBuilder
    }

    func makeListSection(
        from sectionType: TokenSectionsAdapter.SectionType,
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
        sectionItem: TokenSectionsAdapter.SectionItem,
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
        walletModel: any WalletModel,
        isDraggable: Bool,
        inGroupedSection: Bool
    ) -> OrganizeTokensListItemViewModel {
        let identifier = OrganizeTokensListItemViewModel.Identifier(
            walletModelId: walletModel.id.id,
            inGroupedSection: inGroupedSection
        )
        let tokenIcon = tokenIconInfoBuilder.build(
            for: walletModel.tokenItem.amountType,
            in: walletModel.tokenItem.blockchain,
            isCustom: walletModel.isCustom
        )

        return OrganizeTokensListItemViewModel(
            id: identifier,
            tokenIcon: tokenIcon,
            balance: fiatBalance(for: walletModel),
            hasDerivation: true,
            isTestnet: walletModel.tokenItem.blockchain.isTestnet,
            isNetworkUnreachable: walletModel.state.isBlockchainUnreachable,
            isDraggable: isDraggable
        )
    }

    private func makeListItemViewModel(
        userToken: TokenSectionsAdapter.UserToken,
        isDraggable: Bool,
        inGroupedSection: Bool
    ) -> OrganizeTokensListItemViewModel {
        let blockchain = userToken.blockchainNetwork.blockchain
        let isTestnet = blockchain.isTestnet
        let identifier = OrganizeTokensListItemViewModel.Identifier(
            walletModelId: userToken.walletModelId.id,
            inGroupedSection: inGroupedSection
        )

        if let token = token(from: userToken) {
            let tokenIcon = tokenIconInfoBuilder.build(
                for: .token(value: token),
                in: blockchain,
                isCustom: token.isCustom
            )

            return OrganizeTokensListItemViewModel(
                id: identifier,
                tokenIcon: tokenIcon,
                balance: .empty,
                hasDerivation: false,
                isTestnet: isTestnet,
                isNetworkUnreachable: false,
                isDraggable: isDraggable
            )
        }

        let tokenIcon = tokenIconInfoBuilder.build(
            for: .coin,
            in: blockchain,
            isCustom: userToken.isCustom
        )

        return OrganizeTokensListItemViewModel(
            id: identifier,
            tokenIcon: tokenIcon,
            balance: .empty,
            hasDerivation: false,
            isTestnet: isTestnet,
            isNetworkUnreachable: false,
            isDraggable: isDraggable
        )
    }

    private func token(
        from userToken: TokenSectionsAdapter.UserToken
    ) -> BlockchainSdk.Token? {
        guard let contractAddress = userToken.contractAddress else { return nil }

        return BlockchainSdk.Token(
            name: userToken.name,
            symbol: userToken.symbol,
            contractAddress: contractAddress,
            decimalCount: userToken.decimalCount,
            id: userToken.id
        )
    }

    private func fiatBalance(for walletModel: any WalletModel) -> LoadableTokenBalanceView.State {
        LoadableTokenBalanceViewStateBuilder()
            .build(type: walletModel.fiatTotalTokenBalanceProvider.formattedBalanceType, icon: .trailing)
    }
}
