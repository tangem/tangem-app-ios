//
//  MultiWalletSectionItemsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct MultiWalletSectionItemsFactory {
    func makeSectionViewModel(
        from sectionType: TokenSectionsAdapter.SectionType, atIndex index: Int
    ) -> MultiWalletMainContentPlainSectionViewModel {
        switch sectionType {
        case .plain:
            return MultiWalletMainContentPlainSectionViewModel(id: index, title: nil)
        case .group(let blockchainNetwork):
            let title = Localization.walletNetworkGroupTitle(blockchainNetwork.blockchain.displayName)
            return MultiWalletMainContentPlainSectionViewModel(id: blockchainNetwork, title: title)
        }
    }

    func makeSectionItemViewModel(
        from sectionItem: TokenSectionsAdapter.SectionItem,
        contextActionsProvider: TokenItemContextActionsProvider,
        contextActionsDelegate: TokenItemContextActionDelegate,
        tapAction: @escaping (WalletModelId) -> Void,
        yieldApyTapAction: ((TokenItem) -> Void)?
    ) -> TokenItemViewModel {
        let (id, provider, tokenItem, tokenIconInfo) = TokenItemInfoProviderItemBuilder()
            .mapTokenItemViewModel(from: sectionItem)

        return TokenItemViewModel(
            id: id,
            tokenItem: tokenItem,
            tokenIcon: tokenIconInfo,
            infoProvider: provider,
            contextActionsProvider: contextActionsProvider,
            contextActionsDelegate: contextActionsDelegate,
            tokenTapped: tapAction,
            yieldApyTapped: yieldApyTapAction
        )
    }
}
