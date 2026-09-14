//
//  PolymarketOutcomeStyle.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public enum PolymarketOutcomeStyle: Hashable {
    case affirmative
    case negative
}

// MARK: - Domain mapping

public extension PolymarketOutcomeStyle {
    init(outcomeIndex: Int) {
        self = outcomeIndex == 0 ? .affirmative : .negative
    }

    init(binaryOutcomeName: String) {
        self = binaryOutcomeName.lowercased() == Constants.negativeOutcome ? .negative : .affirmative
    }

    private enum Constants {
        static let negativeOutcome = "no"
    }
}

// MARK: - Colors

public extension PolymarketOutcomeStyle {
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
