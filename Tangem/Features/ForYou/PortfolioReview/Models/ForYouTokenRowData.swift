//
//  ForYouTokenRowData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct SwiftUI.Color
import TangemUI

/// Content of a single token row (asset aggregate, per-network child, or the "Other" bucket).
struct ForYouTokenRowData: Identifiable, Equatable {
    let id: String
    /// The concrete token this row resolves to, when it has one; `nil` for aggregate/unmapped rows.
    let tokenItem: TokenItem?
    let symbol: String
    /// Carries a network glyph only for per-network child rows.
    let tokenIconInfo: TokenIconInfo?
    let sentiment: Sentiment?
    let indicatorColor: Color?
    let subtitle: Subtitle
    let end: End
    let isLoading: Bool

    /// How current this row's value is (`.fresh` when there's no resolved value to show).
    var freshness: Freshness {
        switch end {
        case .values(_, _, let freshness): freshness
        case .unavailable: .fresh
        }
    }

    /// Trailing content of a row.
    enum End: Equatable {
        /// Resolved balance; `nil` fiat (loading / no rate) renders as an unmasked dash.
        case values(fiat: String?, percent: String, freshness: Freshness)
        /// Couldn't resolve — a warning label rendered in place of the share; fiat shows as a dash.
        case unavailable(label: String)
    }

    /// How current a shown value is — drives the stale-balance affordance on the row.
    enum Freshness: Equatable {
        /// Up to date — shown plainly.
        case fresh
        /// Being refreshed; the last known value is shown and shimmers.
        case refreshing
        /// Couldn't be refreshed; the cached value is shown and marked with a sync-error icon.
        case outdated
    }

    /// Aggregate coin-indicator outlook for the token over the selected period.
    enum Sentiment: Equatable {
        case positive
        case neutral
        case negative

        init(_ outlook: TokenSummaryOutlook) {
            switch outlook {
            case .positive: self = .positive
            case .neutral: self = .neutral
            case .negative: self = .negative
            }
        }
    }

    /// Plain phrase (aggregate / "Other" rows) or a "network · amount" pair; `nil` amount renders as an unmasked dash.
    enum Subtitle: Equatable {
        case text(String)
        case dotted(String, String?)
    }
}
