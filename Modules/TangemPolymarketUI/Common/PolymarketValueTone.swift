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
    case success
    case gain
    case loss

    public init(pnl: Decimal) {
        switch pnl {
        case let pnl where pnl > 0: self = .gain
        case let pnl where pnl < 0: self = .loss
        default: self = .neutral
        }
    }

    var textColor: Color {
        switch self {
        case .neutral: DesignSystem.Color.textPrimary
        case .success: DesignSystem.Color.textStatusSuccess
        case .gain: DesignSystem.Color.textAccentBlue
        case .loss: DesignSystem.Color.textAccentRed
        }
    }
}
