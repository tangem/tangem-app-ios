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

/// Builds the Portfolio Review rows from aggregated groups — pure (groups in, view models out), unit-tested on fixtures.
struct PortfolioRowBuilder {
    private let balanceFormatter = BalanceFormatter()
    private let iconBuilder = TokenIconInfoBuilder()
    private let percentFormatter = PercentFormatter()

    func build(
        topHoldings: [PortfolioReviewAggregator.Group],
        other: [PortfolioReviewAggregator.Group]
    ) -> [ForYouTokenListItem] {
        let total = (topHoldings + other).reduce(Decimal.zero) { $0 + $1.amountInFiat }

        var items = topHoldings.map { makeAssetItem(group: $0, total: total) }
        if !other.isEmpty {
            items.append(makeOtherItem(other: other, total: total))
        }
        return items
    }
}

// MARK: - Rows

private extension PortfolioRowBuilder {
    func makeAssetItem(group: PortfolioReviewAggregator.Group, total: Decimal) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: group.key,
            assetRow: assetRow(for: group, total: total),
            networkRows: group.networks.map { networkRow(for: $0, total: total) },
            isExpanded: false,
            // A still-loading asset is inert: nothing to reveal until its balances resolve.
            isExpandable: group.availability != .loading
        )
    }

    func assetRow(for group: PortfolioReviewAggregator.Group, total: Decimal) -> ForYouTokenRowData {
        ForYouTokenRowData(
            id: group.key,
            symbol: group.symbol,
            tokenIconInfo: iconBuilder.build(from: group.tokenItem, isCustom: group.isCustom),
            sentiment: Self.placeholderSentiment, // [REDACTED_TODO_COMMENT]
            subtitle: .text(assetSubtitle(tokenItem: group.tokenItem, networkCount: group.networks.count)),
            end: end(availability: group.availability, fiat: group.amountInFiat, total: total),
            isLoading: group.availability == .loading
        )
    }

    func networkRow(for network: PortfolioReviewAggregator.NetworkGroup, total: Decimal) -> ForYouTokenRowData {
        ForYouTokenRowData(
            id: network.id,
            symbol: network.sample.symbol,
            tokenIconInfo: iconBuilder.build(from: network.sample.tokenItem, isCustom: network.sample.isCustom),
            sentiment: Self.placeholderSentiment,
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
                symbol: Localization.commonOther,
                tokenIconInfo: nil,
                sentiment: nil,
                subtitle: .text(assetCountString(other.count)),
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
        case .loading:
            return .values(fiat: AppConstants.enDashSign, percent: "", freshness: .fresh)
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
        case .content, .loading, .unreachable, .noAddress: .fresh
        }
    }

    func networkSubtitle(_ network: PortfolioReviewAggregator.NetworkGroup) -> ForYouTokenRowData.Subtitle {
        let name = network.sample.networkName

        switch network.availability {
        case .content, .cache, .onlyCache:
            return .dotted(name, balanceFormatter.formatCryptoBalance(network.amountInCrypto, currencyCode: network.sample.symbol))
        case .unreachable:
            return .text(name)
        case .loading, .noAddress:
            return .dotted(name, AppConstants.enDashSign)
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

    func assetCountString(_ count: Int) -> String {
        // [REDACTED_TODO_COMMENT]
        "\(count) assets"
    }
}

// MARK: - Constants

private extension PortfolioRowBuilder {
    static let otherID = "for_you_other_assets"
    static let placeholderSentiment: ForYouTokenRowData.Sentiment = .positive // [REDACTED_TODO_COMMENT]
}
