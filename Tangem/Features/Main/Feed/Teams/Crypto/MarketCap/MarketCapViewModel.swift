//
//  MarketCapViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

// [REDACTED_TODO_COMMENT]
final class MarketCapViewModel: ObservableObject {
    let totalMarketCap = "$ 2.44 T"
    let totalMarketCapChange = "1.18%"
    // [REDACTED_TODO_COMMENT]
    let metrics: [Metric] = [
        Metric(title: "Fear & greed", status: "Extreme Fear", appearance: .negative, value: "13", progress: 0.13),
        Metric(title: "Altcoin index", status: "Altcoin Growth", appearance: .positive, value: "56", progress: 0.56),
    ]
}

extension MarketCapViewModel {
    struct Metric: Identifiable {
        enum Appearance {
            case negative
            case positive
        }

        var id: String { title }

        let title: String
        let status: String
        let appearance: Appearance
        let value: String
        let progress: CGFloat
    }
}
