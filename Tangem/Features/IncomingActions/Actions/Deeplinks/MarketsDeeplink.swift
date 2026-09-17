//
//  MarketsDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://markets[?order&interval]`
///
/// Unknown values are left to the filter factory, which substitutes its defaults.
struct MarketsDeeplink: HostNamedDeeplink, Equatable {
    static let host = "markets"

    let order: String?
    let interval: String?

    var action: DeeplinkNavigationAction { .markets(self) }
}

// MARK: - Parsing

extension MarketsDeeplink {
    private enum Keys {
        static let order = "order"
        static let interval = "interval"
    }

    init(link: DeeplinkURL) throws {
        try link.query.validate(Shared.tokenId, Shared.networkId, Shared.promoCode)

        order = link.query.unchecked(Keys.order, lowercased: true)
        interval = link.query.unchecked(Keys.interval, lowercased: true)
    }
}

// MARK: - Navigation

extension MarketsDeeplink {
    /// `order` and `interval` fall back independently: an invalid or missing value for one must not influence
    /// the other. Only `interval` given resolves to `order = .rating`, the factory's default.
    var filter: MarketsDeeplinkFilter {
        MarketsDeeplinkFilterFactory().make(orderRawValue: order, intervalRawValue: interval)
    }
}
