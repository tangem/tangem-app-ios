//
//  PortfolioReviewMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

/// Turns the selected wallet's models into the Portfolio Review view state: extract → aggregate → build rows.
struct PortfolioReviewMapper {
    private let rowBuilder = PortfolioRowBuilder()

    func map(walletModels: [any WalletModel]) -> PortfolioReviewViewModel.ViewState {
        let holdings = walletModels.map(makeHolding)
        let (topHoldings, other) = PortfolioReviewAggregator.aggregate(holdings)
        let groups = topHoldings + other

        guard !isStillResolving(walletModels: walletModels, groups: groups) else {
            return .loading
        }

        return .content(.init(
            tokenList: rowBuilder.build(topHoldings: topHoldings, other: other),
            periodSegments: ForYouPeriodSegment.all, // [REDACTED_TODO_COMMENT]
            chart: chart(topHoldings: topHoldings, other: other)
        ))
    }
}

// MARK: - Chart

private extension PortfolioReviewMapper {
    /// Feeds every group to the gauge (it takes the top-4 as segments and the full sum as the centre total).
    func chart(
        topHoldings: [PortfolioReviewAggregator.Group],
        other: [PortfolioReviewAggregator.Group]
    ) -> PortfolioReviewViewModel.ViewState.Chart {
        let groups = topHoldings + other
        guard !groups.isEmpty else {
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
    func makeHolding(_ walletModel: any WalletModel) -> PortfolioReviewAggregator.TokenHolding {
        let tokenItem = walletModel.tokenItem
        let fiatBalance = walletModel.fiatAvailableBalanceProvider.balanceType
        let availability = Self.availability(for: fiatBalance)

        return PortfolioReviewAggregator.TokenHolding(
            id: walletModel.id.id,
            groupKey: tokenItem.currencyId ?? walletModel.id.id,
            networkKey: tokenItem.networkId,
            networkName: tokenItem.networkName,
            symbol: tokenItem.currencySymbol,
            tokenItem: tokenItem,
            isCustom: walletModel.isCustom,
            // Crypto shows whenever known (incl. no-rate custom); fiat only when there's a value.
            amountInCrypto: availability.showsCrypto ? walletModel.availableBalanceProvider.balanceType.value : nil,
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

    /// Whole-screen skeleton only while everything is still unresolved; once anything resolves,
    /// still-loading rows fall back to per-row skeletons.
    func isStillResolving(walletModels: [any WalletModel], groups: [PortfolioReviewAggregator.Group]) -> Bool {
        walletModels.isEmpty || (!groups.isEmpty && groups.allSatisfy { $0.availability == .loading })
    }
}
