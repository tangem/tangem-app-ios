//
//  MarketsWidgetType+UI.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MarketsWidgetType {
    // [REDACTED_TODO_COMMENT]
    var headerTitle: String {
        switch self {
        case .market:
            return "Market"
        case .news:
            return "News"
        case .earn:
            return "Earn with Tangem"
        case .pulse:
            return "Market Pulse"
        }
    }
}
