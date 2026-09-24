//
//  YieldModuleClaimRewardsSectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct YieldModuleClaimRewardsSectionView: View {
    let section: YieldModuleClaimViewData.Section

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .multilineTextAlignment(.leading)

            ForEach(Array(section.rewards.enumerated()), id: \.element.id) { index, reward in
                if index > 0 {
                    Separator(color: Colors.Stroke.primary)
                }

                rewardRow(reward)
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private func rewardRow(_ reward: YieldModuleClaimViewData.Reward) -> some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: reward.iconInfo, size: Constants.iconSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(reward.symbol)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                Text(reward.networkName)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                if let fiatAmount = reward.fiatAmount {
                    Text(fiatAmount)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                }

                Text(reward.amount)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
        }
    }
}

// MARK: - Constants

private extension YieldModuleClaimRewardsSectionView {
    enum Constants {
        static let iconSize = CGSize(bothDimensions: 36)
    }
}
