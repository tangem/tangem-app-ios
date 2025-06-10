//
//  TokenContextActionsSectionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenContextActionsSectionBuilder {
    func buildContextActionsSections(
        tokenItem: TokenItem,
        walletModelId: WalletModelId,
        userWalletModel: UserWalletModel,
        canNavigateToMarketsDetails: Bool,
        canHideToken: Bool
    ) -> [TokenContextActionsSection] {
        let hideTokenSection = TokenContextActionsSection(items: [.hide])

        // We don't have walletModel for token without derivation
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == walletModelId }) else {
            var sections: [TokenContextActionsSection] = []

            if canHideToken {
                sections.append(hideTokenSection)
            }

            return sections
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
            sections.append(hideTokenSection)
        }

        return sections
    }
}
