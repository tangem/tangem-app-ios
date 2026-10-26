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
    case neutral
}

// MARK: - Domain mapping

public extension PolymarketOutcomeStyle {
    init(outcomeIndex: Int) {
        self = outcomeIndex == 0 ? .affirmative : .negative
    }

    /// The positions endpoints may omit the index, leaving only the label Polymarket prints.
    init(outcomeIndex: Int?, name: String) {
        guard let outcomeIndex else {
            self = Constants.negativeOutcomes.contains(name.lowercased()) ? .negative : .affirmative
            return
        }

        self.init(outcomeIndex: outcomeIndex)
    }

    private enum Constants {
        static let negativeOutcomes: Set<String> = ["no", "under"]
    }
}

// MARK: - Colors

public extension PolymarketOutcomeStyle {
    var backgroundColor: Color {
        switch self {
        case .affirmative: DesignSystem.Color.bgStatusInfoSubtle
        case .negative: DesignSystem.Color.bgStatusErrorSubtle
        case .neutral: DesignSystem.Color.bgTransparentPrimary
        }
    }

    var foregroundColor: Color {
        switch self {
        case .affirmative: DesignSystem.Color.textStatusInfo
        case .negative: DesignSystem.Color.textStatusError
        case .neutral: DesignSystem.Color.textPrimary
        }
    }
}
