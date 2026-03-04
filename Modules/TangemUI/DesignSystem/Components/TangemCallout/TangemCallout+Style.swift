//
//  TangemCallout+Style.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Style

extension TangemCallout {
    var textFont: Font { .Tangem.caption2Semibold }
    var shape: AnyInsettableShape { AnyInsettableShape(.capsule) }

    func textColor(color: CalloutColor) -> Color {
        switch color {
        case .green: Color.Tangem.Markers.textGreen
        case .gray: Color.Tangem.Markers.textDisabled
        }
    }

    func iconColor(color: CalloutColor) -> Color {
        switch color {
        case .green: Color.Tangem.Markers.textGreen
        case .gray: Color.Tangem.Markers.textDisabled
        }
    }

    func backgroundColor(color: CalloutColor) -> Color {
        switch color {
        case .green: Color.Tangem.Markers.backgroundTintedGreen
        case .gray: Color.Tangem.Markers.backgroundSolidGray
        }
    }

    func alignment(arrowAlignment: ArrowAlignment) -> Alignment {
        switch arrowAlignment {
        case .top: .topLeading
        case .bottom: .bottomLeading
        }
    }
}
