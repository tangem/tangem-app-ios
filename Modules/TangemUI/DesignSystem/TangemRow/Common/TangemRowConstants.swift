//
//  TangemRowConstants.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import SwiftUI

public enum TangemRowConstants {
    public enum Style {
        public enum Title {
            public static let font = Font.Tangem.Body16.medium
            public static let color: Color = .Tangem.Text.Neutral.primary
        }

        public enum Subtitle {
            public static let font = Font.Tangem.Caption12.medium
            public static let color: Color = .Tangem.Text.Neutral.secondary
        }

        public enum BottomTrailingText {
            public static let font = Font.Tangem.Caption11.semibold
            public static let color: Color = .Tangem.Text.Neutral.secondary
        }
    }

    enum Spacings {
        static let imageSpacing = SizeUnit.x3
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
