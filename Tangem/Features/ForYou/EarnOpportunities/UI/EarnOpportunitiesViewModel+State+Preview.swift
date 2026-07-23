//
//  EarnOpportunitiesViewModel+State+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization
import TangemUI

extension EarnOpportunitiesViewModel.ViewState {
    static let preview: Self = .content(.init(
        subtitle: EarnRewardSubtitle(
            prefix: "Max potential rewards",
            chip: "$455.83/year",
            suffix: nil
        ),
        list: .accounts([mainAccount, familyAccount])
    ))

    static let previewSuggestions: Self = .content(.init(
        subtitle: EarnRewardSubtitle(
            prefix: "Get up to APY",
            chip: "14.20%",
            suffix: "annually"
        ),
        list: .suggestions([
            EarnSuggestionRowData(id: "atom", tokenIconInfo: previewIcon("Cosmos"), name: "Cosmos", network: "Cosmos network", rateText: "APY 14.20 %", productText: "Staking"),
            EarnSuggestionRowData(id: "sol", tokenIconInfo: previewIcon("Solana"), name: "Solana", network: "Solana network", rateText: "APY 7.05 %", productText: "Staking"),
            EarnSuggestionRowData(id: "usdc", tokenIconInfo: previewIcon("USDC"), name: "USDC", network: "Ethereum network", rateText: "APY 5.40 %", productText: "Yield Mode"),
        ])
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
            EarnTokenRowData(id: "main_eth", tokenIconInfo: previewIcon("Ethereum"), name: "Ethereum", network: "Ethereum Network", rewardText: "+ $312.40/year", apyText: "APY 4.50%"),
            EarnTokenRowData(id: "main_atom", tokenIconInfo: previewIcon("Cosmos"), name: "Cosmos", network: "Cosmos Network", rewardText: "+ $58.20/year", apyText: "APY 14.20%"),
            EarnTokenRowData(id: "main_dot", tokenIconInfo: previewIcon("Polkadot"), name: "Polkadot", network: "Polkadot Network", rewardText: "+ $23.40/year", apyText: "APY 11.80%"),
        ],
        isExpanded: false
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
            EarnTokenRowData(id: "family_sol", tokenIconInfo: previewIcon("Solana"), name: "Solana", network: "Solana Network", rewardText: "+ $41.83/year", apyText: "APY 19.44%"),
            EarnTokenRowData(id: "family_usdt", tokenIconInfo: previewIcon("Tether"), name: "Tether", network: "Solana Network", rewardText: "+ $20/year", apyText: "APY 3.44%"),
        ],
        isExpanded: true
    )

    private static func previewIcon(_ name: String) -> TokenIconInfo {
        TokenIconInfo(
            name: name,
            blockchainIconAsset: nil,
            imageURL: nil,
            isCustom: false,
            customTokenColor: nil
        )
    }
}
