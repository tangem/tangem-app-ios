//
//  Colors+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

public extension Colors {
    enum Text {
        enum Neutral {
            public static let primary: Color = .dynamic(light: Darks.dark6, dark: Base.white)
            public static let primaryInverted: Color = .dynamic(light: Base.white, dark: Darks.dark6)
            public static let primaryInvertedConstant: Color = Base.white
            public static let secondary: Color = .dynamic(light: Darks.dark2, dark: Lights.light5)
            public static let tertiary: Color = Darks.dark1
        }

        enum Status {
            public static let textAccent: Color = Blue.azure
        }

        public static let textDisabled: Color = .dynamic(light: Lights.light4, dark: Darks.dark3)
        public static let textWarning: Color = .dynamic(light: Red.amaranth, dark: Red.flamingo)
        public static let textAttention: Color = .dynamic(light: Yellow.tangerine, dark: Yellow.mustard)
    }

    enum Icon {
        public static let iconPrimary1: Color = .dynamic(light: Darks.dark6, dark: Base.white)
        public static let iconPrimary2: Color = .dynamic(light: Base.white, dark: Darks.dark6)
        public static let iconSecondary: Color = .dynamic(light: Darks.dark2, dark: Lights.light5)
        public static let iconInformative: Color = Darks.dark1
        public static let iconInactive: Color = .dynamic(light: Lights.light4, dark: Darks.dark3)
        public static let iconAccent: Color = Blue.azure
        public static let iconWarning: Color = .dynamic(light: Red.amaranth, dark: Red.flamingo)
        public static let iconAttention: Color = .dynamic(light: Yellow.tangerine, dark: Yellow.mustard)
        public static let iconConstant: Color = Base.white
    }

    enum Button {
        public static let buttonPrimary: Color = .dynamic(light: Darks.dark6, dark: Lights.light2)
        public static let buttonSecondary: Color = .dynamic(light: Lights.light2, dark: Darks.dark4)
        public static let buttonDisabled: Color = .dynamic(light: Lights.light2, dark: Darks.dark5)
        public static let buttonPositive: Color = Blue.azure
    }
}

private extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        let uiColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        }
        return Color(uiColor: uiColor)
    }
}
