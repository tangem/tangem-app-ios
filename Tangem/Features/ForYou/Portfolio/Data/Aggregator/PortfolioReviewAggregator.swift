//
//  PortfolioReviewAggregator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum PortfolioReviewAggregator {
    /// Ranks the wallet's holdings into the top-N assets shown individually plus an "Other" bucket.
    static func aggregate(
        _ holdings: [TokenHolding],
        topHoldingsCount: Int = 4
    ) -> (topHoldings: [Group], other: [Group]) {
        holdings.filter(\.withBalance)
            .groupedByAsset()
            .rankedByFiat()
            .splitTop(max: topHoldingsCount)
    }
}

// MARK: - Holdings pipeline

private extension Array where Element == PortfolioReviewAggregator.TokenHolding {
    /// One `Group` per cross-network asset, in first-seen order (a later stable sort keeps ties in it).
    func groupedByAsset() -> [PortfolioReviewAggregator.Group] {
        let buckets = grouped(by: \.groupKey)

        return unique(by: \.groupKey).compactMap { sample in
            guard let bucket = buckets[sample.groupKey] else { return nil }
            return PortfolioReviewAggregator.Group(
                key: sample.groupKey,
                symbol: sample.symbol,
                tokenItem: sample.tokenItem,
                isCustom: sample.isCustom,
                holdings: bucket,
                networks: bucket.groupedByNetwork()
            )
        }
    }

    /// One `NetworkGroup` per network (derivation-independent), summed across accounts, sorted by fiat desc.
    func groupedByNetwork() -> [PortfolioReviewAggregator.NetworkGroup] {
        let buckets = grouped(by: \.networkKey)

        return unique(by: \.networkKey)
            .compactMap { sample -> PortfolioReviewAggregator.NetworkGroup? in
                guard let bucket = buckets[sample.networkKey] else { return nil }
                return PortfolioReviewAggregator.NetworkGroup(
                    id: sample.networkKey,
                    sample: sample,
                    holdings: bucket
                )
            }
            .stableSorted { $0.amountInFiat > $1.amountInFiat }
    }
}

// MARK: - Ranking

private extension Array where Element == PortfolioReviewAggregator.Group {
    func rankedByFiat() -> [Element] {
        stableSorted { $0.amountInFiat > $1.amountInFiat }
    }

    func splitTop(max: Int) -> (topHoldings: [Element], other: [Element]) {
        (Array(prefix(max)), Array(dropFirst(max)))
    }
}

// MARK: - Stable sort

private extension Array {
    /// Like `sorted(by:)` but stable: elements the predicate treats as equal keep their original (first-seen) order.
    func stableSorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> [Element] {
        enumerated()
            .sorted { lhs, rhs in
                if areInIncreasingOrder(lhs.element, rhs.element) { return true }
                if areInIncreasingOrder(rhs.element, lhs.element) { return false }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
