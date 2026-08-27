//
//  PortfolioReviewMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

/// Turns the selected accounts' stored tokens into the Portfolio Review view state: extract → aggregate → build rows.
struct PortfolioReviewMapper {
    private let rowBuilder = PortfolioRowBuilder()

    func map(
        tokenItems: [TokenItemType],
        totalBalance: TotalBalanceState,
        indicators: [String: [TokenSummaryIndicator]],
        timeframe: TokenSummaryIndicator.Timeframe
    ) -> (state: PortfolioReviewViewModel.ViewState, displayedTokenItems: Set<TokenItem>) {
        let holdings = tokenItems.map(makeHolding)
        let (topHoldings, other, addressless) = PortfolioReviewAggregator.aggregate(holdings)
        let groups = topHoldings + other

        guard !isStillResolving(groups: groups, totalBalance: totalBalance) else {
            return (.loading, [])
        }

        // Nothing to rank (no tokens / all zero / nothing derived) → NoData chart, tokens still listed, no skeleton.
        guard !groups.isEmpty else {
            let reason = emptyChartReason(for: totalBalance)
            let emptyGroups = PortfolioReviewAggregator.aggregateEmpty(holdings)
            return (
                .content(.init(
                    tokenList: rowBuilder.build(topHoldings: emptyGroups, other: [], addressless: [], indicators: indicators, timeframe: timeframe),
                    periodSegments: ForYouPeriodSegment.all,
                    chart: .noData(reason),
                    showsAddFunds: reason == .noAmount
                )),
                displayedTokenItems(in: emptyGroups)
            )
        }

        return (
            .content(.init(
                tokenList: rowBuilder.build(topHoldings: topHoldings, other: other, addressless: addressless, indicators: indicators, timeframe: timeframe),
                periodSegments: ForYouPeriodSegment.all,
                chart: chart(topHoldings: topHoldings, other: other, totalBalance: totalBalance),
                showsAddFunds: false
            )),
            displayedTokenItems(in: groups + addressless)
        )
    }
}

// MARK: - Chart

private extension PortfolioReviewMapper {
    /// Feeds every group to the gauge (it takes the top-4 as segments and the full sum as the centre total).
    func chart(
        topHoldings: [PortfolioReviewAggregator.Group],
        other: [PortfolioReviewAggregator.Group],
        totalBalance: TotalBalanceState
    ) -> PortfolioReviewViewModel.ViewState.Chart {
        let groups = topHoldings + other
        guard !groups.isEmpty else {
            return .noData(.cantLoad)
        }

        // A failed total can't be charted even if some tokens loaded — "can't load", not a donut on a partial sum.
        if case .failed = totalBalance {
            return .noData(.cantLoad)
        }

        let total = groups.reduce(Decimal.zero) {
            $0 + $1.amountInFiat
        }

        guard total > 0 else {
            return .noData(.noAmount)
        }

        let topShare = topHoldings.reduce(Decimal.zero) {
            $0 + $1.amountInFiat
        } / total

        return .loaded(
            assets: groups.map { SummaryGaugeAsset(id: $0.key, name: $0.tokenItem.name, fiatValue: $0.amountInFiat) },
            assetCount: topHoldings.count,
            topHoldingPercent: PercentFormatter().format(topShare, option: .yield)
        )
    }
}

// MARK: - Holding extraction

private extension PortfolioReviewMapper {
    /// Includes the "Other" bucket, excludes zero-balance holdings — the set the outdated-data banner is scoped to.
    func displayedTokenItems(in groups: [PortfolioReviewAggregator.Group]) -> Set<TokenItem> {
        Set(groups.flatMap(\.holdings).map(\.tokenItem))
    }

    func makeHolding(_ item: TokenItemType) -> PortfolioReviewAggregator.TokenHolding {
        switch item {
        case .default(let walletModel): makeDerivedHolding(walletModel)
        case .withoutDerivation(let tokenItem): makeAddresslessHolding(tokenItem)
        }
    }

    /// Nothing is derived yet, so there's no balance to fetch and no rate to apply — only the token's identity is known.
    func makeAddresslessHolding(_ tokenItem: TokenItem) -> PortfolioReviewAggregator.TokenHolding {
        PortfolioReviewAggregator.TokenHolding(
            groupKey: tokenItem.groupKey,
            networkKey: tokenItem.networkId,
            networkName: tokenItem.networkName,
            symbol: tokenItem.currencySymbol,
            tokenItem: tokenItem,
            // Only the "not in Tangem's list" half is knowable here; the custom-derivation half needs a derived path.
            isCustom: tokenItem.id == nil,
            amountInCrypto: nil,
            amountInFiat: nil,
            availability: .noAddress
        )
    }

    func makeDerivedHolding(_ walletModel: any WalletModel) -> PortfolioReviewAggregator.TokenHolding {
        let tokenItem = walletModel.tokenItem
        // Total (available + staked), matching the main screen — available-only shrinks staked assets into "Other".
        let fiatBalance = walletModel.fiatTotalTokenBalanceProvider.balanceType
        let availability = Self.availability(for: fiatBalance)

        return PortfolioReviewAggregator.TokenHolding(
            groupKey: tokenItem.groupKey,
            networkKey: tokenItem.networkId,
            networkName: tokenItem.networkName,
            symbol: tokenItem.currencySymbol,
            tokenItem: tokenItem,
            isCustom: walletModel.isCustom,
            // Crypto shows whenever known (incl. no-rate custom); fiat only when there's a value.
            amountInCrypto: availability.showsCrypto ? walletModel.totalTokenBalanceProvider.balanceType.value : nil,
            amountInFiat: Self.fiatAmount(for: fiatBalance, availability: availability),
            availability: availability
        )
    }

    /// Row fiat. A `.noAccount` balance (e.g. an unfunded XRP wallet) is a confirmed-empty zero, so it's
    /// dropped like any zero holding; other states carry their value or stay `nil` while unresolved.
    static func fiatAmount(for balance: TokenBalanceType, availability: PortfolioReviewAggregator.Availability) -> Decimal? {
        if case .empty(.noAccount) = balance {
            return 0
        }
        return availability.showsValue ? balance.value : nil
    }

    /// Balance status → row availability: `.some`/`.none` cached value splits refreshing from nothing-yet, and could-not-refresh from unreachable.
    static func availability(for balance: TokenBalanceType) -> PortfolioReviewAggregator.Availability {
        switch balance {
        case .loading(.some): return .cache
        case .loading(.none): return .loading
        case .failure(.some): return .onlyCache
        case .failure(.none): return .unreachable
        case .empty(.noData): return .loading
        case .empty(.noDerivation): return .noAddress
        case .empty(.custom): return .noRate
        case .empty, .loaded: return .content
        }
    }

    func isStillResolving(groups: [PortfolioReviewAggregator.Group], totalBalance: TotalBalanceState) -> Bool {
        if !groups.isEmpty {
            return groups.allSatisfy { $0.availability == .loading }
        }

        switch totalBalance {
        case .loading:
            return true
        case .empty, .failed, .loaded:
            return false
        }
    }

    /// Empty-state chart reason: a failed total reads as "can't load"; a genuinely empty/zero wallet as "no amount".
    func emptyChartReason(for totalBalance: TotalBalanceState) -> PortfolioReviewViewModel.ViewState.Chart.NoData {
        if case .failed = totalBalance {
            return .cantLoad
        }
        return .noAmount
    }
}

// MARK: - TokenItem+GroupKey

private extension TokenItem {
    /// Same asset across accounts/derivations → one key: `currencyId`, or network + lowercased contract for customs.
    var groupKey: String {
        switch self {
        case .token(let token, _):
            return token.id ?? "\(networkId)_\(token.contractAddress.lowercased())"
        case .blockchain(let network):
            return network.blockchain.currencyId
        }
    }
}
