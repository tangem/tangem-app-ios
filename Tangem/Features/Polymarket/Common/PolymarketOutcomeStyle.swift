//
//  PolymarketOutcomeStyle.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

enum PolymarketOutcomeStyle: Hashable {
    case affirmative
    case negative
}

// MARK: - Domain mapping

extension PolymarketOutcomeStyle {
    init(outcomeIndex: Int) {
        self = outcomeIndex == 0 ? .affirmative : .negative
    }
}

// MARK: - Colors

extension PolymarketOutcomeStyle {
    var backgroundColor: Color {
        switch self {
        case .affirmative: DesignSystem.Color.bgStatusInfoSubtle
        case .negative: DesignSystem.Color.bgStatusErrorSubtle
        }
    }

    var foregroundColor: Color {
        switch self {
        case .affirmative: DesignSystem.Color.textBrand
        case .negative: DesignSystem.Color.textStatusError
        }
    }
}
