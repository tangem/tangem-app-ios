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
        case .loading(.some): return .cache
        case .loading(.none): return .loading
        case .failure(.some): return .onlyCache
        case .failure(.none): return .unreachable
        case .empty(.noData): return .loading
        case .empty(.noDerivation): return .noAddress
        case .empty, .loaded: return .content
        }
    }

    /// Whole-screen skeleton while nothing's resolved yet — the simplified UI has no per-row loading.
    func isStillResolving(walletModels: [any WalletModel], groups: [PortfolioReviewAggregator.Group]) -> Bool {
        walletModels.isEmpty || (!groups.isEmpty && groups.allSatisfy { $0.availability == .loading })
    }
}
