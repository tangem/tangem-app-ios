//
//  PolymarketValueTone.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public enum PolymarketValueTone: Hashable, Sendable {
    case neutral
    case positive
    case negative

    public init(_ value: Decimal) {
        switch value {
        case let value where value > 0: self = .positive
        case let value where value < 0: self = .negative
        default: self = .neutral
        }
    }

    var textColor: Color {
        switch self {
        case .neutral: DesignSystem.Color.textPrimary
        case .positive: DesignSystem.Color.textStatusSuccess
        case .negative: DesignSystem.Color.textStatusError
        }
    }
}
