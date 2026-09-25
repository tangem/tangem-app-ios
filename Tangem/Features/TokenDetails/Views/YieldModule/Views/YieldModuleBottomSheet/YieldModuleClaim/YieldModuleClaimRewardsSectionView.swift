//
//  YieldModuleClaimRewardsSectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct YieldModuleClaimRewardsSectionView: View {
    let section: YieldModuleClaimViewData.Section

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.rowSpacing) {
            Text(section.title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.leading)

            ForEach(Array(section.rewards.enumerated()), id: \.element.id) { index, reward in
                if index > 0 {
                    Separator(color: DesignSystem.Color.borderSecondary)
                }

                rewardRow(reward)
            }
        }
        .defaultRoundedBackground(
            with: DesignSystem.Color.bgOpaquePrimary,
            cornerRadius: Constants.cornerRadius
        )
    }

    private func rewardRow(_ reward: YieldModuleClaimViewData.Reward) -> some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: reward.iconInfo, size: Constants.iconSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(reward.symbol)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(reward.networkName)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                if let fiatAmount = reward.fiatAmount {
                    Text(fiatAmount)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                }

                Text(reward.amount)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
        }
    }
}

// MARK: - Constants

private extension YieldModuleClaimRewardsSectionView {
    enum Constants {
        static let iconSize = CGSize(bothDimensions: 40)
        static let rowSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 24
    }
}
