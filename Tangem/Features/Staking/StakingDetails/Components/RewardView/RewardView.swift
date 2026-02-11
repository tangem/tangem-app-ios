//
//  RewardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct RewardView: View {
    let data: RewardViewData

    var body: some View {
        content
            .padding(.vertical, 8)
            .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    @ViewBuilder
    var content: some View {
        switch data.state {
        case .noRewards where data.networkType == .cardano:
            Text(Localization.stakingCardanoDetailsRewardsInfoText)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

        case .noRewards:
            Text(Localization.stakingDetailsNoRewardsToClaim)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

        case .automaticRewards where data.networkType == .solana:
            Text(Localization.stakingSolanaDetailsAutoClaimingRewardsDailyText)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

        case .automaticRewards:
            Text(Localization.stakingDetailsAutoClaimingRewardsDailyText)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

        case .rewards(let claimable, let fiatFormatted, let cryptoFormatted, let action):
            Button(action: action) {
                HStack(spacing: 4) {
                    SensitiveText(fiatFormatted)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                    Text(AppConstants.dotSign)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                    SensitiveText(cryptoFormatted)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)

                    Spacer(minLength: 12)

                    if claimable {
                        Assets.chevron.image
                            .renderingMode(.template)
                            .foregroundColor(Colors.Icon.informative)
                    }
                }
            }
        }
    }
}

#Preview("RewardView") {
    ZStack {
        Colors.Background.secondary.ignoresSafeArea()

        GroupedSection(
            [
                RewardViewData(state: .noRewards, networkType: .solana),
                RewardViewData(
                    state: .rewards(
                        claimable: true,
                        fiatFormatted: "24.12$",
                        cryptoFormatted: "23.421 SOL",
                        action: {}
                    ),
                    networkType: .solana
                ),
            ]
        ) {
            RewardView(data: $0)
        }
        .interItemSpacing(12)
        .innerContentPadding(12)
        .padding()
    }
}
