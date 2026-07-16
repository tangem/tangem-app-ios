//
//  PortfolioReviewMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemLocalization

/// Maps the selected wallet's models into the Portfolio Review view state: flattens each model into an
/// aggregator `Entry`, delegates grouping/ranking to `PortfolioReviewAggregator`, then builds the rows
/// and formats the display strings.
struct PortfolioReviewMapper {
    private let balanceFormatter = BalanceFormatter()
    private let iconBuilder = TokenIconInfoBuilder()
    private let percentFormatter = PercentFormatter()

    func map(walletModels: [any WalletModel]) -> PortfolioReviewViewModel.ViewState {
        let entries = walletModels.map(makeEntry)
        let (topHoldings, other) = PortfolioReviewAggregator.aggregate(entries)

        // Portfolio total = the sum of the shown holdings (top + other). Derived from the rows rather
        // than the separate total-balance provider, so shares resolve exactly when the balances do.
        let totalFiat = (topHoldings + other).reduce(Decimal.zero) { $0 + $1.fiat }

        var items = topHoldings.map { makeAssetItem(group: $0, total: totalFiat) }

        if !other.isEmpty {
            let otherFiat = other.reduce(Decimal.zero) { $0 + $1.fiat }
            items.append(makeOtherItem(assetCount: other.count, fiat: otherFiat, total: totalFiat))
        }

        return PortfolioReviewViewModel.ViewState(
            tokenList: items,
            periodSegments: ForYouPeriodSegment.all // [REDACTED_TODO_COMMENT]
        )
    }
}

// MARK: - Entry extraction

private extension PortfolioReviewMapper {
    func makeEntry(_ walletModel: any WalletModel) -> PortfolioReviewAggregator.Entry {
        let tokenItem = walletModel.tokenItem
        let availability = Self.availability(for: walletModel.fiatAvailableBalanceProvider.balanceType)

        return PortfolioReviewAggregator.Entry(
            id: walletModel.id.id,
            groupKey: tokenItem.currencyId ?? walletModel.id.id,
            networkKey: tokenItem.networkId,
            networkName: tokenItem.networkName,
            symbol: tokenItem.currencySymbol,
            tokenItem: tokenItem,
            isCustom: walletModel.isCustom,
            // Keep the (possibly cached) value for any state that shows one — including cache / only-cache.
            crypto: availability.showsValue ? walletModel.availableBalanceProvider.balanceType.value : nil,
            fiat: availability.showsValue ? walletModel.fiatAvailableBalanceProvider.balanceType.value : nil,
            availability: availability
        )
    }

    /// Maps the balance status onto the row availability. A cached value distinguishes "refreshing"
    /// (`.loading(.some)` → cache) from "nothing yet" (`.loading(.none)` → loading), and "couldn't refresh
    /// but have a value" (`.failure(.some)` → only-cache) from "unreachable" (`.failure(.none)`).
    static func availability(for balance: TokenBalanceType) -> PortfolioReviewAggregator.Availability {
        switch balance {
        case .loading(.some):
            return .cache
        case .loading(.none):
            return .loading
        case .failure(.some):
            return .onlyCache
        case .failure(.none):
            return .unreachable
        case .empty(.noDerivation):
            return .noAddress
        case .empty, .loaded:
            return .content
        }
    }

    /// The row's value freshness for the states that show a value.
    func valueSource(for availability: PortfolioReviewAggregator.Availability) -> ForYouTokenRowData.End.ValueSource {
        switch availability {
        case .cache: .cache
        case .onlyCache: .onlyCache
        default: .actual
        }
    }
}

// MARK: - Row building

private extension PortfolioReviewMapper {
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

    func assetRow(for group: PortfolioReviewAggregator.Group, total: Decimal) -> ForYouTokenRow {
        switch group.availability {
        case .loading:
            return .loading(id: group.key)
        case .content, .cache, .onlyCache:
            return .content(assetContent(group, end: .values(
                fiat: fiatString(group.fiat),
                percent: percentString(group.fiat, total: total),
                source: valueSource(for: group.availability)
            )))
        case .unreachable:
            return .content(assetContent(group, end: .unavailable(label: Localization.commonUnreachable)))
        case .noAddress:
            return .content(assetContent(group, end: .unavailable(label: Localization.commonNoAddress)))
        }
    }

    func assetContent(_ group: PortfolioReviewAggregator.Group, end: ForYouTokenRowData.End) -> ForYouTokenRowData {
        ForYouTokenRowData(
            id: group.key,
            symbol: group.symbol,
            tokenIconInfo: iconBuilder.build(from: group.tokenItem, isCustom: group.isCustom),
            sentiment: Self.placeholderSentiment, // [REDACTED_TODO_COMMENT]
            subtitle: .text(assetSubtitle(tokenItem: group.tokenItem, networkCount: group.networks.count)),
            end: end
        )
    }

    func networkRow(for network: PortfolioReviewAggregator.NetworkGroup, total: Decimal) -> ForYouTokenRow {
        let sample = network.sample

        switch network.availability {
        case .loading:
            return .loading(id: network.id)
        case .content, .cache, .onlyCache:
            return .content(networkContent(
                network,
                subtitle: .dotted(sample.networkName, balanceFormatter.formatCryptoBalance(network.crypto, currencyCode: sample.symbol)),
                end: .values(
                    fiat: fiatString(network.fiat),
                    percent: percentString(network.fiat, total: total),
                    source: valueSource(for: network.availability)
                )
            ))
        case .unreachable:
            return .content(networkContent(network, subtitle: .text(sample.networkName), end: .unavailable(label: Localization.commonUnreachable)))
        case .noAddress:
            return .content(networkContent(network, subtitle: .dotted(sample.networkName, AppConstants.enDashSign), end: .unavailable(label: Localization.commonNoAddress)))
        }
    }

    func networkContent(
        _ network: PortfolioReviewAggregator.NetworkGroup,
        subtitle: ForYouTokenRowData.Subtitle,
        end: ForYouTokenRowData.End
    ) -> ForYouTokenRowData {
        ForYouTokenRowData(
            id: network.id,
            symbol: network.sample.symbol,
            tokenIconInfo: iconBuilder.build(from: network.sample.tokenItem, isCustom: network.sample.isCustom),
            sentiment: Self.placeholderSentiment,
            subtitle: subtitle,
            end: end
        )
    }

    func makeOtherItem(assetCount: Int, fiat: Decimal, total: Decimal) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: Self.otherID,
            assetRow: .content(
                ForYouTokenRowData(
                    id: Self.otherID,
                    symbol: Localization.commonOther,
                    tokenIconInfo: nil,
                    sentiment: nil,
                    subtitle: .text(assetCountString(assetCount)),
                    end: .values(fiat: fiatString(fiat), percent: percentString(fiat, total: total), source: .actual)
                )
            ),
            networkRows: [],
            isExpanded: false,
            isExpandable: false
        )
    }
}

// MARK: - Subtitles & formatting

private extension PortfolioReviewMapper {
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

private extension PortfolioReviewMapper {
    static let otherID = "for_you_other_assets"
    static let placeholderSentiment: ForYouTokenRowData.Sentiment = .positive // [REDACTED_TODO_COMMENT]
}
