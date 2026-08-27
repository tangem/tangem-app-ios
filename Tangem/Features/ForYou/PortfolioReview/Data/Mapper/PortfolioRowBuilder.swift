//
//  PortfolioRowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemLocalization

/// Builds the Portfolio Review rows from aggregated groups.
struct PortfolioRowBuilder {
    private let balanceFormatter = BalanceFormatter()
    private let iconBuilder = TokenIconInfoBuilder()
    private let percentFormatter = PercentFormatter()
    private let sentimentMapper = PortfolioReviewSentimentMapper()

    func build(
        topHoldings: [PortfolioReviewAggregator.Group],
        other: [PortfolioReviewAggregator.Group],
        addressless: [PortfolioReviewAggregator.Group],
        indicators: [String: [TokenSummaryIndicator]],
        timeframe: TokenSummaryIndicator.Timeframe
    ) -> [ForYouTokenListItem] {
        let total = (topHoldings + other).reduce(Decimal.zero) { $0 + $1.amountInFiat }

        // Addressless assets are concrete rows, so they precede the "Other" summary that closes the list.
        var items = (topHoldings + addressless).map { group in
            makeAssetItem(
                group: group,
                total: total,
                sentiment: sentimentMapper.sentiment(for: indicators[group.symbol.uppercased()], timeframe: timeframe)
            )
        }
        if !other.isEmpty {
            items.append(makeOtherItem(other: other, total: total))
        }
        return items
    }
}

// MARK: - Rows

private extension PortfolioRowBuilder {
    func makeAssetItem(group: PortfolioReviewAggregator.Group, total: Decimal, sentiment: ForYouTokenRowData.Sentiment?) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: group.key,
            assetRow: assetRow(for: group, total: total, sentiment: sentiment),
            networkRows: group.networks.map { networkRow(for: $0, groupKey: group.key, total: total, sentiment: sentiment) },
            isExpanded: false,
            // Inert while loading; a single-network asset has nothing to reveal, so it stays a tap-to-open row.
            isExpandable: group.availability != .loading && group.networks.count > 1
        )
    }

    func assetRow(for group: PortfolioReviewAggregator.Group, total: Decimal, sentiment: ForYouTokenRowData.Sentiment?) -> ForYouTokenRowData {
        ForYouTokenRowData(
            id: group.key,
            tokenItem: group.tokenItem,
            symbol: group.symbol,
            tokenIconInfo: iconBuilder.build(from: group.tokenItem, isCustom: group.isCustom),
            sentiment: sentiment,
            subtitle: .text(assetSubtitle(tokenItem: group.tokenItem, networkCount: group.networks.count)),
            end: end(availability: group.availability, fiat: group.amountInFiat, total: total),
            isLoading: group.availability == .loading
        )
    }

    func networkRow(for network: PortfolioReviewAggregator.NetworkGroup, groupKey: String, total: Decimal, sentiment: ForYouTokenRowData.Sentiment?) -> ForYouTokenRowData {
        ForYouTokenRowData(
            // Namespace under the asset group to avoid id collisions across networks/tokens.
            id: "\(groupKey)/\(network.id)",
            tokenItem: network.sample.tokenItem,
            symbol: network.sample.tokenItem.name,
            tokenIconInfo: iconBuilder.build(from: network.sample.tokenItem, isCustom: network.sample.isCustom),
            sentiment: sentiment,
            subtitle: networkSubtitle(network),
            end: end(availability: network.availability, fiat: network.amountInFiat, total: total),
            isLoading: network.availability == .loading
        )
    }

    func makeOtherItem(other: [PortfolioReviewAggregator.Group], total: Decimal) -> ForYouTokenListItem {
        let fiat = other.reduce(Decimal.zero) { $0 + $1.amountInFiat }

        return ForYouTokenListItem(
            id: Self.otherID,
            assetRow: ForYouTokenRowData(
                id: Self.otherID,
                tokenItem: nil,
                symbol: Localization.commonOther,
                tokenIconInfo: nil,
                sentiment: nil,
                subtitle: .text(Localization.commonAssetsCount(other.count)),
                end: .values(fiat: fiatString(fiat), percent: percentString(fiat, total: total), freshness: .fresh),
                isLoading: false
            ),
            networkRows: [],
            isExpanded: false,
            isExpandable: false
        )
    }
}

// MARK: - End & subtitles

private extension PortfolioRowBuilder {
    /// Trailing content per availability: a value carrying its freshness, or a dash while loading.
    func end(availability: PortfolioReviewAggregator.Availability, fiat: Decimal, total: Decimal) -> ForYouTokenRowData.End {
        switch availability {
        case .content, .cache, .onlyCache:
            return .values(
                fiat: fiatString(fiat),
                percent: percentString(fiat, total: total),
                freshness: freshness(for: availability)
            )
        case .loading, .noRate:
            return .values(fiat: nil, percent: "", freshness: .fresh)
        case .unreachable:
            return .unavailable(label: Localization.commonUnreachable)
        case .noAddress:
            return .unavailable(label: Localization.commonNoAddress)
        }
    }

    /// A refreshing value shimmers; a value stuck on cache (couldn't refresh) is marked outdated.
    func freshness(for availability: PortfolioReviewAggregator.Availability) -> ForYouTokenRowData.Freshness {
        switch availability {
        case .cache: .refreshing
        case .onlyCache: .outdated
        case .content, .loading, .unreachable, .noAddress, .noRate: .fresh
        }
    }

    func networkSubtitle(_ network: PortfolioReviewAggregator.NetworkGroup) -> ForYouTokenRowData.Subtitle {
        let name = network.sample.networkName

        switch network.availability {
        case .content, .cache, .onlyCache, .noRate:
            return .dotted(name, balanceFormatter.formatCryptoBalance(network.amountInCrypto, currencyCode: network.sample.symbol))
        case .unreachable:
            return .text(name)
        case .loading, .noAddress:
            return .dotted(name, nil)
        }
    }

    func assetSubtitle(tokenItem: TokenItem, networkCount: Int) -> String {
        if networkCount > 1 {
            return Localization.commonNetworksCount(networkCount)
        }

        if tokenItem.isBlockchain {
            return Localization.commonMainNetwork
        }

        // Single-network token: its standard (e.g. "ERC20"), falling back to the network name.
        return tokenItem.contractName ?? tokenItem.networkName
    }

    func fiatString(_ value: Decimal) -> String {
        balanceFormatter.formatFiatBalance(value)
    }

    func percentString(_ value: Decimal, total: Decimal) -> String {
        guard total > 0, value > 0 else { return "" }
        return percentFormatter.format(value / total, option: .yield)
    }
}

// MARK: - Constants

private extension PortfolioRowBuilder {
    static let otherID = "for_you_other_assets"
}
