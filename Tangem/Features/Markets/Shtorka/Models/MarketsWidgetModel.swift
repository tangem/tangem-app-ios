//
//  MarketsWidgetModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsWidgetModel: Identifiable, Hashable, Equatable {
    var id: String { type.id }

    let type: MarketsWidgetType
    let isEnabled: Bool
    let order: Int

    #warning("Need to implement localizations")
    var headerTitle: String? {
        switch type {
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
