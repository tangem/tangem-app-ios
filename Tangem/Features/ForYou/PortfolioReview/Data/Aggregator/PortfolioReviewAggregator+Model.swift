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
        var hasBalance: Bool {
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
            networks.map(\.availability).resolvedAvailability
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
            holdings.map(\.availability).resolvedAvailability
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
        /// Held with no fiat rate (custom token): crypto is shown, fiat is dashed.
        case noRate

        var showsValue: Bool {
            switch self {
            case .content, .cache, .onlyCache: true
            case .loading, .unreachable, .noAddress, .noRate: false
            }
        }

        var showsCrypto: Bool {
            switch self {
            case .content, .cache, .onlyCache, .noRate: true
            case .loading, .unreachable, .noAddress: false
            }
        }
    }
}

extension Array where Element == PortfolioReviewAggregator.Group {
    /// A zero draws no arc, so it earns no rank colour either.
    var chartableKeys: [String] {
        filter { $0.amountInFiat > 0 }.map(\.key)
    }
}

private extension Array where Element == PortfolioReviewAggregator.TokenHolding {
    var fiatSum: Decimal {
        reduce(Decimal.zero) {
            $0 + ($1.amountInFiat ?? 0)
        }
    }
}

private extension Array where Element == PortfolioReviewAggregator.Availability {
    /// Value-wins collapse; among valueless siblings the more telling wins: unreachable > noRate > loading.
    var resolvedAvailability: PortfolioReviewAggregator.Availability {
        let valueBearing = filter(\.showsValue)
        if !valueBearing.isEmpty {
            if valueBearing.contains(.onlyCache) {
                return .onlyCache
            }
            if valueBearing.contains(.cache) {
                return .cache
            }
            return .content
        }

        if contains(.unreachable) { return .unreachable }
        if contains(.noRate) { return .noRate }
        if contains(.loading) { return .loading }
        return .noAddress
    }
}
