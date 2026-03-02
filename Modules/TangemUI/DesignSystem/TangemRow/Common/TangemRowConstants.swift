//
//  TangemRowConstants.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import SwiftUI

enum TangemRowConstants {
    enum Style {
        enum Title {
            static let font: Font = .Tangem.bodySemibold
            static let color: Color = .Tangem.Text.Neutral.primary
        }

        enum Subtitle {
            static let font: Font = .Tangem.caption2Semibold
            static let color: Color = .Tangem.Text.Neutral.secondary
        }

        enum BottomTrailingText {
            static let font: Font = .Tangem.caption2Semibold
            static let color: Color = .Tangem.Text.Neutral.secondary
        }
    }

    enum Spacings {
        static let imageSpacing = SizeUnit.x2
        static let multilineSpacing = SizeUnit.x1

        static let topLineInnerSpacing = SizeUnit.x1
        static let bottomLineInnerSpacing = SizeUnit.x1
    }

    enum Layout {
        enum MinWidthRatio {
            static let primaryLeading: CGFloat = 0.3
            static let secondaryLeading: CGFloat = 0.32
        }
    }
}
