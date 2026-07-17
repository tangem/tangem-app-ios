//
//  ForYouTokenRowData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

/// Content of a single token row (asset aggregate, per-network child, or the "Other" bucket).
struct ForYouTokenRowData: Identifiable, Equatable {
    let id: String
    let symbol: String
    /// Carries a network glyph only for per-network child rows.
    let tokenIconInfo: TokenIconInfo?
    let sentiment: Sentiment?
    let subtitle: Subtitle
    let end: End

    /// How current this row's value is (`.fresh` when there's no resolved value to show).
    var freshness: Freshness {
        switch end {
        case .values(_, _, let freshness): freshness
        case .unavailable: .fresh
        }
    }

    /// Trailing content of a row.
    enum End: Equatable {
        /// Resolved balance: the fiat total, its portfolio share, and how current the value is.
        case values(fiat: String, percent: String, freshness: Freshness)
        /// Couldn't resolve — a warning label rendered in place of the share; fiat shows as a dash.
        case unavailable(label: String)
    }

    /// How current a shown value is — drives the stale-balance affordance on the row.
    enum Freshness: Equatable {
        /// Up to date — shown plainly.
        case fresh
        /// Being refreshed; the last known value is shown and shimmers.
        case refreshing
        /// Couldn't be refreshed; the last known (cached) value is shown with a cloud-exclamation icon.
        case outdated
    }

    /// Placeholder price-change sentiment; real data lands with the price-change pipeline.
    enum Sentiment: Equatable {
        case positive
        case neutral
        case negative
    }

    /// A plain phrase (aggregate / "Other" rows) or a "network · amount" pair rendered with a
    /// vector dot separator (per-network rows).
    enum Subtitle: Equatable {
        case text(String)
        case dotted(String, String)
    }
}
