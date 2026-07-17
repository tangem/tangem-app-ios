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

/// Flattens the wallet's models into aggregator holdings, then builds the view-state rows.
struct PortfolioReviewMapper {
    private let balanceFormatter = BalanceFormatter()
    private let iconBuilder = TokenIconInfoBuilder()
    private let percentFormatter = PercentFormatter()

    func map(walletModels: [any WalletModel]) -> PortfolioReviewViewModel.ViewState {
        let holdings = walletModels.map(makeHolding)
        let (topHoldings, other) = PortfolioReviewAggregator.aggregate(holdings)
        let groups = topHoldings + other

        // Still resolving → whole-screen skeleton (no models yet, or every asset's balance still loading).
        // The simplified UI has no per-row loading state, so a partial load stays on the skeleton.
        if walletModels.isEmpty || (!groups.isEmpty && groups.allSatisfy { $0.availability == .loading }) {
            return .loading
        }

        // Portfolio total = the sum of the shown holdings (top + other). Derived from the rows rather
        // than the separate total-balance provider, so shares resolve exactly when the balances do.
        let totalFiat = groups.reduce(Decimal.zero) { $0 + $1.amountInFiat }

        var items = topHoldings.map { makeAssetItem(group: $0, total: totalFiat) }

        if !other.isEmpty {
            let otherFiat = other.reduce(Decimal.zero) { $0 + $1.amountInFiat }
            items.append(makeOtherItem(assetCount: other.count, fiat: otherFiat, total: totalFiat))
        }

        return .content(.init(
            tokenList: items,
            periodSegments: ForYouPeriodSegment.all // [REDACTED_TODO_COMMENT]
        ))
    }
}

// MARK: - Holding extraction

private extension PortfolioReviewMapper {
    func makeHolding(_ walletModel: any WalletModel) -> PortfolioReviewAggregator.TokenHolding {
        let tokenItem = walletModel.tokenItem
        let availability = Self.availability(for: walletModel.fiatAvailableBalanceProvider.balanceType)

        return PortfolioReviewAggregator.TokenHolding(
            id: walletModel.id.id,
            groupKey: tokenItem.currencyId ?? walletModel.id.id,
            networkKey: tokenItem.networkId,
            networkName: tokenItem.networkName,
            symbol: tokenItem.currencySymbol,
            tokenItem: tokenItem,
            isCustom: walletModel.isCustom,
            // Keep the (possibly cached) value for any state that shows one.
            amountInCrypto: availability.showsValue ? walletModel.availableBalanceProvider.balanceType.value : nil,
            amountInFiat: availability.showsValue ? walletModel.fiatAvailableBalanceProvider.balanceType.value : nil,
            availability: availability
        )
    }

    /// Balance status → row availability: `.some`/`.none` cached value splits refreshing from nothing-yet, and could-not-refresh from unreachable.
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

    func assetRow(for group: PortfolioReviewAggregator.Group, total: Decimal) -> ForYouTokenRowData {
        ForYouTokenRowData(
            id: group.key,
            symbol: group.symbol,
            tokenIconInfo: iconBuilder.build(from: group.tokenItem, isCustom: group.isCustom),
            sentiment: Self.placeholderSentiment, // [REDACTED_TODO_COMMENT]
            subtitle: .text(assetSubtitle(tokenItem: group.tokenItem, networkCount: group.networks.count)),
            end: end(availability: group.availability, fiat: group.amountInFiat, total: total)
        )
    }

    func networkRow(for network: PortfolioReviewAggregator.NetworkGroup, total: Decimal) -> ForYouTokenRowData {
        ForYouTokenRowData(
            id: network.id,
            symbol: network.sample.symbol,
            tokenIconInfo: iconBuilder.build(from: network.sample.tokenItem, isCustom: network.sample.isCustom),
            sentiment: Self.placeholderSentiment,
            subtitle: networkSubtitle(network),
            end: end(availability: network.availability, fiat: network.amountInFiat, total: total)
        )
    }

    func makeOtherItem(assetCount: Int, fiat: Decimal, total: Decimal) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: Self.otherID,
            assetRow: ForYouTokenRowData(
                id: Self.otherID,
                symbol: Localization.commonOther,
                tokenIconInfo: nil,
                sentiment: nil,
                subtitle: .text(assetCountString(assetCount)),
                end: .values(fiat: fiatString(fiat), percent: percentString(fiat, total: total))
            ),
            networkRows: [],
            isExpanded: false,
            isExpandable: false
        )
    }
}

// MARK: - End & subtitles

private extension PortfolioReviewMapper {
    /// Trailing content per availability: cache/only-cache render as a plain value; loading shows a dash.
    func end(availability: PortfolioReviewAggregator.Availability, fiat: Decimal, total: Decimal) -> ForYouTokenRowData.End {
        switch availability {
        case .content, .cache, .onlyCache:
            return .values(fiat: fiatString(fiat), percent: percentString(fiat, total: total))
        case .loading:
            return .values(fiat: AppConstants.enDashSign, percent: "")
        case .unreachable:
            return .unavailable(label: Localization.commonUnreachable)
        case .noAddress:
            return .unavailable(label: Localization.commonNoAddress)
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

private extension PortfolioReviewMapper {
    static let otherID = "for_you_other_assets"
    static let placeholderSentiment: ForYouTokenRowData.Sentiment = .positive // [REDACTED_TODO_COMMENT]
}
