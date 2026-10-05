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
import TangemAccounts

struct YieldModuleClaimRewardsSectionView: View {
    let section: YieldModuleClaimViewData.Section

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            headerView
                .padding(.horizontal, Constants.rowHorizontalPadding)
                .padding(.vertical, Constants.headerVerticalPadding)

            ForEach(Array(section.rewards.enumerated()), id: \.element.id) { index, reward in
                if index > 0 {
                    Separator(color: DesignSystem.Color.borderSecondary)
                        .padding(.horizontal, Constants.rowHorizontalPadding)
                }

                rewardRow(reward)
                    .padding(Constants.rewardRowPadding)
            }
        }
        .defaultRoundedBackground(
            with: DesignSystem.Color.bgTransparentPrimary,
            verticalPadding: .zero,
            horizontalPadding: .zero,
            cornerRadius: Constants.cornerRadius
        )
    }

    private var headerView: some View {
        HStack(spacing: Constants.headerSpacing) {
            Text(section.title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.leading)

            if let storage = section.storage {
                Spacer(minLength: Constants.headerSpacing)

                storageView(storage)
            }
        }
    }

    private func storageView(_ storage: YieldModuleClaimViewData.Storage) -> some View {
        HStack(spacing: Constants.accountSpacing) {
            Text(storage.name)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            if case .account(_, let icon) = storage {
                AccountIconView(data: icon, settings: .extraSmallSized)
            }
        }
    }

    private func rewardRow(_ reward: YieldModuleClaimViewData.Reward) -> some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: reward.iconInfo, size: Constants.iconSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(reward.symbol)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)

                Text(reward.networkName)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                if let fiatAmount = reward.fiatAmount {
                    Text(fiatAmount)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(1)
                }

                Text(reward.amount)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .layoutPriority(1)
        }
    }
}

// MARK: - Constants

private extension YieldModuleClaimRewardsSectionView {
    enum Constants {
        static let iconSize = CGSize(bothDimensions: 40)
        static let rowHorizontalPadding: CGFloat = 16
        static let headerVerticalPadding: CGFloat = 12
        static let rewardRowPadding: CGFloat = 16
        static let headerSpacing: CGFloat = 12
        static let accountSpacing: CGFloat = 4
        static let cornerRadius: CGFloat = 24
    }
}
