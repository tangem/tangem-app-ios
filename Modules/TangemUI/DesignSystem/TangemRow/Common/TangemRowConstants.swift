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
        static let imageSpacing: CGFloat = 12
        static let multilineSpacing: CGFloat = 4

        static let topLineInnerSpacing: CGFloat = 4
    }
}
