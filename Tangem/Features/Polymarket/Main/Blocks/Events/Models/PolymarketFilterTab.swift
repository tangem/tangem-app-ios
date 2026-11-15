//
//  PolymarketFilterTab.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPolymarket
import TangemUI

struct PolymarketFilterTab: TabNavigationItem {
    let id: PolymarketCategoryFilter
    let title: String
}

extension PolymarketFilterTab {
    init?(filter: PolymarketCategoryFilter) {
        switch filter {
        case .games:
            self.init(id: filter, title: Constants.gamesTitle)
        case .props:
            self.init(id: filter, title: Constants.propsTitle)
        case .unknown:
            return nil
        }
    }
}

// MARK: - Constants

private extension PolymarketFilterTab {
    enum Constants {
        // [REDACTED_TODO_COMMENT]
        static let gamesTitle = "Games"
        // [REDACTED_TODO_COMMENT]
        static let propsTitle = "Questions"
    }
}
