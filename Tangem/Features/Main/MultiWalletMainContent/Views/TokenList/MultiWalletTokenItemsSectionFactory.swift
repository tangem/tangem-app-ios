//
//  MultiWalletTokenItemsSectionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct MultiWalletTokenItemsSectionFactory {
    func makeSectionViewModel(
        from sectionType: TokenSectionsAdapter.SectionType, atIndex index: Int
    ) -> MultiWalletMainContentViewModel.SectionViewModel {
        switch sectionType {
        case .plain:
            return MultiWalletMainContentViewModel.SectionViewModel(id: index, title: nil)
        case .group(let blockchainNetwork):
            let title = Localization.walletNetworkGroupTitle(blockchainNetwork.blockchain.displayName)
            return MultiWalletMainContentViewModel.SectionViewModel(id: blockchainNetwork, title: title)
        }
    }

    func makeSectionItemViewModel(
        from sectionItem: TokenSectionsAdapter.SectionItem,
        balanceRestrictionFeatureAvailabilityProvider: BalanceRestrictionFeatureAvailabilityProvider,
        contextActionsProvider: TokenItemContextActionsProvider,
        contextActionsDelegate: TokenItemContextActionDelegate,
        tapAction: @escaping (WalletModelId.ID) -> Void
    ) -> TokenItemViewModel {
        let (id, provider, tokenItem, tokenIconInfo) = TokenItemInfoProviderItemBuilder()
            .mapTokenItemViewModel(from: sectionItem)

        return TokenItemViewModel(
            id: id,
            tokenItem: tokenItem,
            tokenIcon: tokenIconInfo,
            infoProvider: provider,
            balanceRestrictionFeatureAvailabilityProvider: balanceRestrictionFeatureAvailabilityProvider,
            contextActionsProvider: contextActionsProvider,
            contextActionsDelegate: contextActionsDelegate,
            tokenTapped: tapAction
        )
    }
}
