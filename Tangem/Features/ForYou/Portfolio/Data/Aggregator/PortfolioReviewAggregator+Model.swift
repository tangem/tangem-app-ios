//
//  PortfolioReviewAggregator+Model.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PortfolioReviewAggregator {
    /// One token on one network — a flattened `WalletModel`.
    struct TokenHolding {
        let id: String
        /// Cross-network asset key.
        let groupKey: String
        let networkKey: String
        let networkName: String
        let symbol: String
        let tokenItem: TokenItem
        let isCustom: Bool
        let amountInCrypto: Decimal?
        /// In the app currency (crypto × rate).
        let amountInFiat: Decimal?
        let availability: Availability

        /// Keeps `nil`, drops confirmed-zero fiat.
        var withBalance: Bool {
            amountInFiat != 0
        }
    }

    /// One asset across its networks.
    struct Group {
        let key: String
        let symbol: String
        let tokenItem: TokenItem
        let isCustom: Bool
        let holdings: [TokenHolding]
        let networks: [NetworkGroup]

        var amountInFiat: Decimal {
            holdings.fiatSum
        }

        var availability: Availability {
            holdings.availability
        }
    }

    /// One network of an asset.
    struct NetworkGroup {
        let id: String
        let sample: TokenHolding
        let holdings: [TokenHolding]

        var amountInFiat: Decimal {
            holdings.fiatSum
        }

        var amountInCrypto: Decimal {
            holdings.reduce(Decimal.zero) { $0 + ($1.amountInCrypto ?? 0) }
        }

        var availability: Availability {
            holdings.availability
        }
    }

    /// A row's balance status.
    enum Availability {
        case loading
        case content
        /// Stale, refreshing.
        case cache
        /// Couldn't refresh; last value shown.
        case onlyCache
        case unreachable
        case noAddress

        var showsValue: Bool {
            switch self {
            case .content, .cache, .onlyCache: true
            case .loading, .unreachable, .noAddress: false
            }
        }
    }
}

private extension Array where Element == PortfolioReviewAggregator.TokenHolding {
    var fiatSum: Decimal {
        reduce(Decimal.zero) {
            $0 + ($1.amountInFiat ?? 0)
        }
    }

    /// Priority collapse: all-loading → loading; else worst of noAddress > unreachable > onlyCache > cache > content.
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
