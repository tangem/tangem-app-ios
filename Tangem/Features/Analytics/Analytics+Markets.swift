//
//  Analytics+Markets.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum MarketsIntervalTypeSourceType: String {
        case insights = "Insights"
        case price = "Price"
        case chart = "Chart"
    }

    enum MarketsSection: String {
        case crypto = "Crypto"
        case assets = "Assets"
        case earn = "Earn"
    }
}
