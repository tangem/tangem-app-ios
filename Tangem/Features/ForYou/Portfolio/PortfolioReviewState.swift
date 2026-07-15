//
//  PortfolioReviewState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

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
