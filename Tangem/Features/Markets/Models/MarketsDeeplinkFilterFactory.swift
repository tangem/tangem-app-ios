//
//  MarketsDeeplinkFilterFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Builds a `MarketsDeeplinkFilter` out of raw query-string values from a
/// `tangem://markets` deeplink, applying the acceptance-criteria fallbacks
/// (defaults: `order = rating`, `interval = 24h`; each parameter falls back
/// independently of the other).
struct MarketsDeeplinkFilterFactory {
    func make(orderRawValue: String?, intervalRawValue: String?) -> MarketsDeeplinkFilter {
        let order = mapOrder(orderRawValue) ?? MarketsDeeplinkFilter.default.order
        let interval = mapInterval(intervalRawValue) ?? MarketsDeeplinkFilter.default.interval
        return MarketsDeeplinkFilter(order: order, interval: interval)
    }

    // MARK: - Private Implementation

    private func mapOrder(_ value: String?) -> MarketsListOrderType? {
        guard let value, !value.isEmpty else { return nil }
        return MarketsListOrderType(rawValue: value)
    }

    /// Deeplink contract for `interval` is `24h / 1w / 30d`, which doesn't match
    /// `MarketsPriceIntervalType.rawValue` 1:1 (e.g. `30d` vs `1m`). The mapping
    /// is therefore explicit rather than driven by `MarketsPriceIntervalType(rawValue:)`.
    private func mapInterval(_ value: String?) -> MarketsPriceIntervalType? {
        guard let value, !value.isEmpty else { return nil }
        switch value {
        case "24h": return .day
        case "1w": return .week
        case "30d": return .month
        default: return nil
        }
    }
}
