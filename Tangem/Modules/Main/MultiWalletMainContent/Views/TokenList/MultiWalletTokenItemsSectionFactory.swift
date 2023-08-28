//
//  MultiWalletTokenItemsSectionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct MultiWalletTokenItemsSectionFactory {
    func makeSectionViewModel(
        from sectionType: OrganizeTokensSectionsAdapter.SectionType, atIndex index: Int
    ) -> MultiWalletMainContentViewModel.SectionViewModel {
        switch sectionType {
        case .plain:
            return MultiWalletMainContentViewModel.SectionViewModel(id: index, title: nil)
        case .group(let blockchainNetwork):
            let title = Localization.walletNetworkGroupTitle(blockchainNetwork.blockchain.displayName)
            return MultiWalletMainContentViewModel.SectionViewModel(id: blockchainNetwork, title: title)
        }
    }

    func makeSectionItemViewModels(
        from sectionItems: [OrganizeTokensSectionsAdapter.SectionItem],
        tapAction: @escaping (WalletModel.ID) -> Void
    ) -> [TokenItemViewModel] {
        let iconInfoBuilder = TokenIconInfoBuilder()
        let infoProviders = makeSectionItemInfoProviders(from: sectionItems)

        return infoProviders.map { infoProvider in
            let tokenItem = infoProvider.tokenItem
            let tokenIcon = iconInfoBuilder.build(from: tokenItem)

            return TokenItemViewModel(
                id: infoProvider.id,
                tokenIcon: tokenIcon,
                tokenItem: tokenItem,
                tokenTapped: tapAction,
                infoProvider: infoProvider,
                priceChangeProvider: PriceChangeProviderMock()
            )
        }
    }

    private func makeSectionItemInfoProviders(
        from sectionItems: [OrganizeTokensSectionsAdapter.SectionItem]
    ) -> [TokenItemInfoProvider] {
        return sectionItems.map { sectionItem in
            switch sectionItem {
            case .default(let walletModel):
                return DefaultTokenItemInfoProvider(walletModel: walletModel)
            case .withoutDerivation(let userToken):
                let converter = StorageEntryConverter()
                let walletModelId = userToken.walletModelId
                let blockchain = userToken.blockchainNetwork.blockchain

                if let token = converter.convertToToken(userToken) {
                    return TokenWithoutDerivationInfoProvider(
                        id: walletModelId,
                        tokenItem: .token(token, blockchain)
                    )
                }

                return TokenWithoutDerivationInfoProvider(
                    id: walletModelId,
                    tokenItem: .blockchain(blockchain)
                )
            }
        }
    }
}
