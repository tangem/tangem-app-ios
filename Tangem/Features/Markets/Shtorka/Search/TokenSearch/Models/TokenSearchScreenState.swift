//
//  TokenSearchScreenState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TokenSearchScreenState: Equatable {
    case idle(IdleContent)
    case searching
    case results(TokenSearchResult)
    case empty
    case error

    struct IdleContent: Equatable {
        let queries: [String]
        let marketAssetViewModels: [MarketTokenItemViewModel]

        static func == (lhs: IdleContent, rhs: IdleContent) -> Bool {
            lhs.queries == rhs.queries
                && lhs.marketAssetViewModels.map(\.tokenId) == rhs.marketAssetViewModels.map(\.tokenId)
        }
    }
}
