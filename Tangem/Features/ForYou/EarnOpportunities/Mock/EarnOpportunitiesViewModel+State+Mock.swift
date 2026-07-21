//
//  EarnOpportunitiesViewModel+State+Mock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

// [REDACTED_TODO_COMMENT]
extension EarnOpportunitiesViewModel.ViewState {
    static let mock: Self = .content(.init(
        subtitle: EarnRewardSubtitle(
            label: Localization.forYouEarnOpportunitiesTokensRewards(""),
            amount: "$455.83/year"
        ),
        accounts: [mainAccount, familyAccount]
    ))

    private static let mainAccount = EarnAccountListItem(
        id: "main",
        account: EarnAccountRowData(
            iconColor: DesignSystem.Color.iconAccentBlue,
            glyph: Assets.Accounts.starAccounts,
            name: "Main Account",
            tokensCountText: Localization.commonTokensCount(7),
            rewardText: "+ $394/year"
        ),
        tokens: [
            EarnTokenRowData(id: "main_eth", name: "Ethereum", network: "Ethereum Network", rewardText: "+ $312.40/year", apyPercent: "APY 4.50%"),
            EarnTokenRowData(id: "main_atom", name: "Cosmos", network: "Cosmos Network", rewardText: "+ $58.20/year", apyPercent: "APY 14.20%"),
            EarnTokenRowData(id: "main_dot", name: "Polkadot", network: "Polkadot Network", rewardText: "+ $23.40/year", apyPercent: "APY 11.80%"),
        ],
        isExpanded: false,
        isExpandable: true
    )

    private static let familyAccount = EarnAccountListItem(
        id: "family",
        account: EarnAccountRowData(
            iconColor: DesignSystem.Color.iconAccentViolet,
            glyph: Assets.Accounts.family,
            name: "Family Account",
            tokensCountText: Localization.commonTokensCount(2),
            rewardText: "+ $61.83/year"
        ),
        tokens: [
            EarnTokenRowData(id: "family_sol", name: "Solana", network: "Solana Network", rewardText: "+ $41.83/year", apyPercent: "APY 19.44%"),
            EarnTokenRowData(id: "family_usdt", name: "Tether", network: "Solana Network", rewardText: "+ $20/year", apyPercent: "APY 3.44%"),
        ],
        isExpanded: true,
        isExpandable: true
    )
}
