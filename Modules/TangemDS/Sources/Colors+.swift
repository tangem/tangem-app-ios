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
        public enum Neutral {
            public static let primary: Color = .dynamic(light: Darks.dark6, dark: Base.white)
            public static let primaryInverted: Color = .dynamic(light: Base.white, dark: Darks.dark6)
            public static let primaryInvertedConstant: Color = Base.white
            public static let secondary: Color = .dynamic(light: Darks.dark2, dark: Lights.light5)
            public static let tertiary: Color = Darks.dark1
        }

        public enum Status {
            public static let accent: Color = Blue.azure
            public static let disabled: Color = .dynamic(light: Lights.light4, dark: Darks.dark3)
            public static let warning: Color = .dynamic(light: Red.amaranth, dark: Red.flamingo)
            public static let attention: Color = .dynamic(light: Yellow.tangerine, dark: Yellow.mustard)
            public static let positive: Color = Green.eucalyptus
        }
    }

    enum Graphic {
        public enum Neutral {
            public static let primary: Color = .dynamic(light: Darks.dark6, dark: Base.white)
            public static let primaryInverted: Color = .dynamic(light: Base.white, dark: Darks.dark6)
            public static let primaryInvertedConstant: Color = Base.white
            public static let secondary: Color = .dynamic(light: Darks.dark2, dark: Lights.light5)
            public static let tertiary: Color = .dynamic(light: Darks.dark1, dark: Darks.dark2)
            public static let tertiaryConstant: Color = Darks.dark1
            public static let quaternary: Color = .dynamic(light: Lights.light4, dark: Darks.dark3)
        }

        public enum Status {
            public static let accent: Color = Blue.azure
            public static let warning: Color = .dynamic(light: Red.amaranth, dark: Red.flamingo)
            public static let attention: Color = .dynamic(light: Yellow.tangerine, dark: Yellow.mustard)
        }
    }

    enum Button {
        public static let backgroundPrimary: Color = .dynamic(light: Darks.dark6, dark: Lights.light1)
        public static let backgroundSecondary: Color = .dynamic(light: Darks.dark6.opacity(0.1), dark: Base.white.opacity(0.1))
        public static let backgroundDisabled: Color = .dynamic(light: Lights.light2, dark: Darks.dark5)
        public static let backgroundPositive: Color = Blue.azure
        public static let textPrimary: Color = .dynamic(light: Lights.light2, dark: Darks.dark4)
        public static let textSecondary: Color = .dynamic(light: Darks.dark6, dark: Lights.light4)
        public static let textDisabled: Color = .dynamic(light: Text.Neutral.tertiary, dark: Text.Neutral.secondary)
        public static let iconPrimary: Color = .dynamic(light: Darks.dark6, dark: Lights.light4)
        public static let iconSecondary: Color = .dynamic(light: Lights.light2, dark: Darks.dark4)
        public static let iconDisabled: Color = .dynamic(light: Lights.light2, dark: Darks.dark5)
        public static let borderPrimary: Color = .dynamic(light: Darks.dark6, dark: Lights.light4)
    }

    enum Surface {
        public static let level1: Color = .dynamic(light: Base.white, dark: Darks.dark6)
        public static let level2: Color = .dynamic(light: Lights.light1, dark: Base.black)
        public static let level3: Color = .dynamic(light: Lights.light1, dark: Darks.dark6)
        public static let level4: Color = .dynamic(light: Base.white, dark: Darks.dark5)
    }

    enum Controls {
        public static let backgroundChecked: Color = .dynamic(light: Darks.dark6, dark: Blue.azure)
        public static let backgroundDefault: Color = .dynamic(light: Lights.light2, dark: Darks.dark4)
        public static let iconDefault: Color = Base.white
        public static let iconDisabled: Color = Base.white
    }

    enum Border {
        public enum Neutral {
            public static let primary: Color = .dynamic(light: Lights.light2, dark: Darks.dark4)
            public static let secondary: Color = .dynamic(light: Lights.light5, dark: Darks.dark4)
        }

        public enum Status {
            public static let accent: Color = Blue.azure
            public static let warning: Color = .dynamic(light: Red.amaranth, dark: Red.flamingo)
            public static let attention: Color = .dynamic(light: Yellow.tangerine, dark: Yellow.mustard)
        }
    }

    enum Field {
        public static let backgroundDefault: Color = .dynamic(light: Lights.light1, dark: Darks.dark5)
        public static let backgroundFocused: Color = .dynamic(light: Lights.light2, dark: Darks.dark4)
        public static let textPlaceholder: Color = Text.Neutral.secondary
        public static let textDefault: Color = Text.Neutral.primary
        public static let textDisabled: Color = Text.Neutral.tertiary
        public static let textInvalid: Color = Text.Status.warning
        public static let borderInvalid: Color = Border.Status.warning
        public static let iconDefault: Color = Graphic.Neutral.tertiary
        public static let iconDisabled: Color = Graphic.Neutral.quaternary
    }

    enum Overlay {
        public static let primary: Color = Overlays.overlay1
        public static let secondary: Color = Overlays.overlay2
    }

    enum Fill {
        public enum Neutral {
            public static let primary: Color = .dynamic(light: Darks.dark6, dark: Base.white)
            public static let primaryInverted: Color = .dynamic(light: Base.white, dark: Darks.dark6)
            public static let primaryConstant: Color = Base.white
            public static let secondary: Color = .dynamic(light: Darks.dark2, dark: Lights.light5)
            public static let tertiaryConstant: Color = Darks.dark1
            public static let quaternary: Color = .dynamic(light: Lights.light4, dark: Darks.dark3)
        }

        public enum Status {
            public static let accent: Color = Blue.azure
            public static let warning: Color = .dynamic(light: Red.amaranth, dark: Red.flamingo)
            public static let attention: Color = .dynamic(light: Yellow.tangerine, dark: Yellow.mustard)
        }
    }

    enum Skeleton {
        public static let backgroundPrimary: Color = .dynamic(light: Lights.light1, dark: Darks.dark5)
    }

    enum Markers {
        public static let backgroundSolidGray: Color = .dynamic(light: Lights.light3, dark: Darks.dark5)
        public static let backgroundSolidBlue: Color = Blue.azure
        public static let backgroundSolidRed: Color = Red.amaranth
        public static let backgroundDisabled: Color = .dynamic(light: Lights.light2, dark: Darks.dark5)
        public static let textGray: Color = .dynamic(light: Darks.dark2, dark: Lights.light4)
        public static let textBlue: Color = Text.Status.accent
        public static let textRed: Color = .dynamic(light: Red.amaranth, dark: Red.flamingo)
        public static let textDisabled: Color = .dynamic(light: Text.Neutral.tertiary, dark: Text.Neutral.secondary)
        public static let iconGray: Color = .dynamic(light: Darks.dark1, dark: Darks.dark2)
        public static let iconBlue: Color = Blue.azure
        public static let iconRed: Color = Red.amaranth
        public static let iconDisabled: Color = .dynamic(light: Lights.light2, dark: Darks.dark5)
        public static let borderGray: Color = .dynamic(light: Lights.light3, dark: Base.white.opacity(0.2))
        public static let borderTintedBlue: Color = Blue.azure.opacity(0.1)
        public static let borderTintedRed: Color = Red.amaranth.opacity(0.1)
        public static let backgroundTintedBlue: Color = Blue.azure.opacity(0.1)
        public static let backgroundTintedRed: Color = Red.amaranth.opacity(0.1)
        public static let backgroundTintedGray: Color = .dynamic(light: Darks.dark6.opacity(0.1), dark: Base.white.opacity(0.1))
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
