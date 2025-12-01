//
//  MarketsWidgetType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsWidgetType: String, Identifiable, CaseIterable {
    case banner
    case market
    case news
    case earn
    case pulse

    var id: String {
        rawValue
    }
}
