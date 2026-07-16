//
//  PortfolioReviewAggregator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Groups entries by asset, ranks by fiat, and splits into top-N holdings + an "Other" bucket.
/// Pure and `WalletModel`-free — ranking rules unit-test on plain `Entry` fixtures.
enum PortfolioReviewAggregator {
    static func aggregate(_ entries: [Entry], topHoldingsCount: Int = 4) -> (topHoldings: [Group], other: [Group]) {
        // Drop positively-zero fiat before grouping; keep nil (still loading / no quote).
        let held = entries.filter { $0.fiat != 0 }
        // Group by cross-network asset key, first-seen order preserved for a stable ranking.
        let groups = orderedGroups(held)
        // Groups is already in first-seen order; a stable sort keeps ties in that order.
        let ranked = groups.sorted { $0.fiat > $1.fiat }
        // Top holdings get their own rows; everything past the cutoff collapses into "Other".
        let topHoldings = Array(ranked.prefix(topHoldingsCount))
        let other = Array(ranked.dropFirst(topHoldingsCount))

        return (topHoldings: topHoldings, other: other)
    }
}

// MARK: - Grouping

private extension PortfolioReviewAggregator {
    /// Group entries by asset key, preserving first-seen order; each group carries its network breakdown.
    static func orderedGroups(_ entries: [Entry]) -> [Group] {
        let buckets = entries.grouped(by: \.groupKey)

        return entries.unique(by: \.groupKey).compactMap { sample in
            guard let bucket = buckets[sample.groupKey] else { return nil }
            return Group(
                key: sample.groupKey,
                symbol: sample.symbol,
                tokenItem: sample.tokenItem,
                entries: bucket,
                networks: orderedNetworks(bucket)
            )
        }
    }

    /// One row per network (derivation-independent), summed across accounts, sorted by fiat desc.
    static func orderedNetworks(_ entries: [Entry]) -> [NetworkGroup] {
        let buckets = entries.grouped(by: \.networkKey)

        return entries.unique(by: \.networkKey)
            .compactMap { sample -> NetworkGroup? in
                guard let bucket = buckets[sample.networkKey] else { return nil }
                return NetworkGroup(id: sample.id, sample: sample, entries: bucket)
            }
            .sorted { $0.fiat > $1.fiat }
    }
}

// MARK: - Model

extension PortfolioReviewAggregator {
    /// A single wallet model flattened into the fields the ranking needs — deliberately `WalletModel`-free.
    struct Entry {
        let id: String
        let groupKey: String
        let networkKey: String
        let networkName: String
        let symbol: String
        let tokenItem: TokenItem
        let crypto: Decimal?
        let fiat: Decimal?
        let availability: Availability
    }

    /// One asset aggregated across its networks.
    struct Group {
        let key: String
        let symbol: String
        let tokenItem: TokenItem
        let entries: [Entry]
        let networks: [NetworkGroup]

        var fiat: Decimal { entries.fiatSum }
        var availability: Availability { entries.availability }
    }

    /// One network of an asset, aggregated across accounts/derivations.
    struct NetworkGroup {
        let id: String
        let sample: Entry
        let entries: [Entry]

        var fiat: Decimal { entries.fiatSum }
        var crypto: Decimal { entries.reduce(Decimal.zero) { $0 + ($1.crypto ?? 0) } }
        var availability: Availability { entries.availability }
    }

    /// Whether a row's underlying balances are still loading, resolved (fresh / stale / could-not-refresh),
    /// unreachable, or missing an address.
    enum Availability {
        case loading
        case content
        /// Stale value, refresh in flight (shown flickering).
        case cache
        /// Couldn't refresh — last known value shown with a sync-error icon.
        case onlyCache
        case unreachable
        case noAddress

        /// Whether the row has a (possibly stale) value to display.
        var showsValue: Bool {
            switch self {
            case .content, .cache, .onlyCache: true
            case .loading, .unreachable, .noAddress: false
            }
        }
    }
}

// MARK: - Helpers

private extension Array where Element == PortfolioReviewAggregator.Entry {
    var fiatSum: Decimal {
        reduce(Decimal.zero) { $0 + ($1.fiat ?? 0) }
    }

    /// Collapses per-entry availability by priority. All-loading → loading. Otherwise, among the resolved
    /// entries: no-address and unreachable (no value at all) win first; then, among value-bearing entries,
    /// the worst freshness dominates (onlyCache > cache > actual).
    var availability: PortfolioReviewAggregator.Availability {
        if allSatisfy({ $0.availability == .loading }) {
            return .loading
        }

        let resolved = filter { $0.availability != .loading }
        if resolved.contains(where: { $0.availability == .noAddress }) {
            return .noAddress
        }
        if resolved.contains(where: { $0.availability == .unreachable }) {
            return .unreachable
        }
        if resolved.contains(where: { $0.availability == .onlyCache }) {
            return .onlyCache
        }
        if resolved.contains(where: { $0.availability == .cache }) {
            return .cache
        }
        return .content
    }
}
