//
//  MarketsDeeplinkFilter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Filter configuration derived from a `tangem://markets?order=...&interval=...` deeplink.
///
/// The type is intentionally just a plain value — resolving raw query strings into
/// valid enum cases (with fallbacks) is the responsibility of
/// `MarketsDeeplinkFilterFactory`.
struct MarketsDeeplinkFilter: Equatable {
    let order: MarketsListOrderType
    let interval: MarketsPriceIntervalType

    /// Default filter used when the deeplink provides no parameters or all of them are invalid.
    static let `default` = MarketsDeeplinkFilter(order: .rating, interval: .day)
}
