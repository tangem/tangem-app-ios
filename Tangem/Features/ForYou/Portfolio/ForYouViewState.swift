//
//  ForYouViewState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

// MARK: - Portfolio review state

/// View-state model for the For You Portfolio Review screen.
enum PortfolioReviewState: Equatable {
    case loading(tokenList: [ForYouTokenListItem])
    case content(Content)

    var tokenList: [ForYouTokenListItem] {
        switch self {
        case .loading(let tokenList): return tokenList
        case .content(let content): return content.tokenList
        }
    }
}

extension PortfolioReviewState {
    struct Content: Equatable {
        let tokenList: [ForYouTokenListItem]
        let periodSegments: [ForYouPeriodSegment]
    }

    /// The placeholder shown until the first real emission — four skeleton rows.
    static var loadingPlaceholder: PortfolioReviewState {
        .loading(
            tokenList: (0 ..< 4).map { index in
                ForYouTokenListItem(
                    id: "loading_\(index)",
                    assetRow: .loading(id: "loading_\(index)"),
                    networkRows: [],
                    isExpanded: false,
                    isExpandable: false
                )
            }
        )
    }
}

// MARK: - Token list

/// One asset row plus its per-network breakdown revealed on expand.
struct ForYouTokenListItem: Identifiable, Equatable {
    let id: String
    let assetRow: ForYouTokenRowData
    let networkRows: [ForYouTokenRowData]
    let isExpanded: Bool
    let isExpandable: Bool
}

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

// MARK: - Wallet tabs

struct ForYouWalletTab: Identifiable, Equatable {
    let id: String
    let name: String
    let isSelected: Bool
    let count: Int?
}

// MARK: - Period picker

struct ForYouPeriodSegment: Identifiable, Hashable {
    let id: String
    let title: String
}

extension ForYouPeriodSegment: TangemSegmentedPickerTextProvider {
    var text: String { title }
}

extension ForYouPeriodSegment {
    // [REDACTED_TODO_COMMENT]
    static let all: [ForYouPeriodSegment] = [
        ForYouPeriodSegment(id: "day", title: "Day"),
        ForYouPeriodSegment(id: "week", title: "Week"),
        ForYouPeriodSegment(id: "month", title: "Month"),
    ]

    static let initial = ForYouPeriodSegment(id: "day", title: "Day")
}
