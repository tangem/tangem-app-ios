//
//  EarnOpportunitiesMapper+RowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemUI

extension EarnOpportunitiesMapper {
    /// Builds rows, subtitles, and formatting for the earn section.
    struct RowBuilder {
        private let balanceFormatter = BalanceFormatter()
        private let percentFormatter = PercentFormatter()

        // MARK: - Rows

        func makeAccountItem(_ account: AccountCandidate, reward: Decimal) -> EarnAccountListItem {
            EarnAccountListItem(
                id: account.id,
                account: EarnAccountRowData(
                    iconColor: AccountModelUtils.UI.iconColor(from: account.icon.color),
                    glyph: AccountModelUtils.UI.iconAsset(from: account.icon.name),
                    name: account.name,
                    tokensCountText: Localization.commonTokensCount(account.holdings.count),
                    rewardAmount: balanceFormatter.formatFiatBalance(reward)
                ),
                tokens: account.holdings.map(makeTokenRow),
                isExpanded: true
            )
        }

        func makeTokenRow(_ holding: HoldingCandidate) -> EarnTokenRowData {
            EarnTokenRowData(
                id: holding.id,
                tokenIconInfo: holding.tokenIconInfo,
                name: holding.currencyName,
                network: Localization.walletNetworkGroupTitle(holding.networkName),
                rewardAmount: rewardAmount(for: holding),
                apyText: holding.apyInfo.rateType.earnBadgeText(percentText: percentFormatter.format(holding.apyInfo.apy, option: .interval))
            )
        }

        func makeSuggestionRow(_ token: EarnTokenModel) -> EarnSuggestionRowData {
            let isNativeToken = token.contractAddress == nil

            return EarnSuggestionRowData(
                id: [token.id, token.networkId, token.earnType.rawValue].joined(separator: "_"),
                token: token,
                tokenIconInfo: TokenIconInfo(
                    name: token.name,
                    blockchainIconAsset: isNativeToken ? nil : token.blockchainIconAsset,
                    imageURL: token.imageUrl,
                    isCustom: false,
                    customTokenColor: nil
                ),
                name: token.name,
                network: Localization.walletNetworkGroupTitle(token.networkName),
                rateText: token.rateText,
                productText: productText(for: token.earnType)
            )
        }

        // MARK: - Subtitles

        /// "Max potential rewards {$X/year}".
        func makeRewardsSubtitle(totalReward: Decimal) -> EarnRewardSubtitle {
            chipSubtitle(
                template: Localization.forYouEarnOpportunitiesTokensRewards,
                chip: .fiat(balanceFormatter.formatFiatBalance(totalReward))
            )
        }

        /// "Get up to {APY x%} annually"; `nil` when there's no rate. `rateText` carries the type,
        /// so the chip stays one localized placeholder instead of hand-joining it around the prefix.
        func makeBestRateSubtitle(best: EarnTokenModel?) -> EarnRewardSubtitle? {
            guard let best else {
                return nil
            }

            return chipSubtitle(
                template: Localization.forYouEarnOpportunitiesNoAvailableTokens,
                chip: .rate(best.rateText)
            )
        }

        /// "All your assets are at work, explore new opportunities".
        func makeAllActiveSubtitle() -> EarnRewardSubtitle {
            EarnRewardSubtitle(prefix: Localization.forYouEarnOpportunitiesAllTokensActive, chip: nil, suffix: nil)
        }
    }
}

// MARK: - Private helpers

private extension EarnOpportunitiesMapper.RowBuilder {
    enum Constants {
        static let chipMarker = "\u{FFFC}"
    }

    /// No fiat rate → `nil` (the row renders it as a dash) instead of "+$0/year".
    func rewardAmount(for holding: EarnOpportunitiesMapper.HoldingCandidate) -> String? {
        guard holding.fiatBalance != nil else {
            return nil
        }

        return balanceFormatter.formatFiatBalance(holding.potentialReward)
    }

    func productText(for earnType: EarnType) -> String {
        switch earnType {
        case .staking: Localization.commonStaking
        case .yieldMode: Localization.commonYieldMode
        }
    }

    /// Splits the localized template around its placeholder for chip rendering.
    func chipSubtitle(template: (String) -> String, chip: EarnRewardSubtitle.Chip?) -> EarnRewardSubtitle {
        let parts = template(Constants.chipMarker).components(separatedBy: Constants.chipMarker)
        let prefix = parts.first?.trimmed() ?? ""
        let suffix = parts.dropFirst().first?.trimmed()

        return EarnRewardSubtitle(
            prefix: prefix,
            chip: chip,
            suffix: suffix?.nilIfEmpty
        )
    }
}
