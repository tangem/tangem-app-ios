//
//  TangemCallout+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Properties

public extension TangemCallout {
    enum ArrowAlignment {
        case top
        case bottom
    }

    struct ColorPalette: Equatable, Sendable {
        public let text: Color
        public let icon: Color
        public let background: Color

        public init(text: Color, icon: Color, background: Color) {
            self.text = text
            self.icon = icon
            self.background = background
        }
    }

    struct Action {
        let icon: Image
        let closure: @MainActor () -> Void
    }
}

// MARK: - Predefined palettes

public extension TangemCallout.ColorPalette {
    static let green = TangemCallout.ColorPalette(
        text: Color.Tangem.Markers.textGreen,
        icon: Color.Tangem.Markers.iconGreen,
        background: Color.Tangem.Markers.backgroundTintedGreen
    )

    static let gray = TangemCallout.ColorPalette(
        text: Color.Tangem.Markers.textDisabled,
        icon: Color.Tangem.Markers.iconGray,
        background: Color.Tangem.Markers.backgroundSolidGray
    )

    static let blue = TangemCallout.ColorPalette(
        text: Color.Tangem.Markers.textBlue,
        icon: Color.Tangem.Markers.iconBlue,
        background: Color.Tangem.Markers.backgroundTintedBlue
    )
}
