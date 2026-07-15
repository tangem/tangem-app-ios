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
    let isLoading: Bool
    let symbol: String
    /// `nil` while loading; carries a network glyph only for per-network child rows.
    let tokenIconInfo: TokenIconInfo?
    let sentiment: Sentiment?
    let subtitle: Subtitle
    let end: End

    /// Trailing content of a row.
    enum End: Equatable {
        /// Resolved balance: the fiat total and its share of the portfolio.
        case values(fiat: String, percent: String)
        /// Couldn't resolve — a warning label rendered in place of the share; fiat shows as a dash.
        case unavailable(label: String)
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

    static func loading(id: String) -> ForYouTokenRowData {
        ForYouTokenRowData(
            id: id,
            isLoading: true,
            symbol: "",
            tokenIconInfo: nil,
            sentiment: nil,
            subtitle: .text(""),
            end: .values(fiat: "", percent: "")
        )
    }
}
