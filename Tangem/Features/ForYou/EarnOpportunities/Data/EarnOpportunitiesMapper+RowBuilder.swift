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
                    rewardText: plusPerYear(reward)
                ),
                tokens: account.holdings.map(makeTokenRow),
                isExpanded: false
            )
        }

        func makeTokenRow(_ holding: HoldingCandidate) -> EarnTokenRowData {
            EarnTokenRowData(
                id: holding.id,
                tokenIconInfo: holding.tokenIconInfo,
                name: holding.currencyName,
                network: Localization.walletNetworkGroupTitle(holding.networkName),
                rewardText: rewardText(for: holding),
                apyText: percentFormatter.format(holding.apyInfo.apy, option: .staking)
            )
        }

        func makeSuggestionRow(_ token: EarnTokenModel) -> EarnSuggestionRowData {
            EarnSuggestionRowData(
                id: [token.id, token.symbol, token.networkName, token.earnType.rawValue].joined(separator: "_"),
                tokenIconInfo: TokenIconInfo(
                    name: token.name,
                    blockchainIconAsset: token.blockchainIconAsset,
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

        /// "Max potential rewards {+$X/year}".
        func makeRewardsSubtitle(totalReward: Decimal) -> EarnRewardSubtitle {
            chipSubtitle(
                template: Localization.forYouEarnOpportunitiesTokensRewards,
                chip: Localization.forYouEarnPerYear(balanceFormatter.formatFiatBalance(totalReward))
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
                chip: best.rateText
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

    func plusPerYear(_ reward: Decimal) -> String {
        "\(AppConstants.plusSign) \(Localization.forYouEarnPerYear(balanceFormatter.formatFiatBalance(reward)))"
    }

    /// No fiat rate → dash instead of "+$0/year".
    func rewardText(for holding: EarnOpportunitiesMapper.HoldingCandidate) -> String {
        guard holding.fiatBalance != nil else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return plusPerYear(holding.potentialReward)
    }

    func productText(for earnType: EarnType) -> String {
        switch earnType {
        case .staking: Localization.commonStaking
        case .yieldMode: Localization.commonYieldMode
        }
    }

    /// Splits the localized template around its placeholder for chip rendering.
    func chipSubtitle(template: (String) -> String, chip: String?) -> EarnRewardSubtitle {
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
