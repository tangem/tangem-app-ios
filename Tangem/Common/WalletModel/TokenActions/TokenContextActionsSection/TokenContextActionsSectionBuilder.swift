//
//  TokenContextActionsSectionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenContextActionsSectionBuilder {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    func buildContextActionsSections(
        tokenItem: TokenItem,
        walletModelId: WalletModelId,
        userWalletModel: UserWalletModel,
        canNavigateToMarketsDetails: Bool,
        canHideToken: Bool
    ) -> [TokenContextActionsSection] {
        // Impossible case
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == walletModelId }) else {
            return []
        }

        var sections: [TokenContextActionsSection] = []

        if canNavigateToMarketsDetails, tokenItem.id != nil {
            let marketsSection = TokenContextActionsSection(items: [.marketsDetails])
            sections.append(marketsSection)
        }

        let tokenActionAvailabilityProvider = TokenActionAvailabilityProvider(userWalletConfig: userWalletModel.config, walletModel: walletModel)

        let baseSectionItems = tokenActionAvailabilityProvider.buildTokenContextActions()

        if !baseSectionItems.isEmpty {
            let baseSection = TokenContextActionsSection(items: baseSectionItems)

            sections.append(baseSection)
        }

        if canHideToken {
            let hideTokenSection = TokenContextActionsSection(items: [.hide])
            sections.append(hideTokenSection)
        }

        return sections
    }
}
