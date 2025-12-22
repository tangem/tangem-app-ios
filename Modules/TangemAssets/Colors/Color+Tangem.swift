//
//  Color+.swift
//  TangemAssets
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Tangem colors

public extension Color {
    enum Tangem {
        public enum Text {}
        public enum Graphic {}
        public enum Status {}
        public enum Button {}
        public enum Surface {}
        public enum Controls {}
        public enum Border {}
        public enum Field {}
        public enum Overlay {}
        public enum Fill {}
        public enum Skeleton {}
        public enum Markers {}
        public enum Visa {}
    }
}

private typealias Primitives = DesignSystemColors.Primitives

// MARK: - Alphas

extension Primitives {
    static let lightAlpha: Color = Base.white
    static let darkAlpha: Color = Darks.dark6
}

// MARK: - Text

public extension Color.Tangem.Text {
    enum Neutral {
        public static let primary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Base.white)
        public static let primaryInverted: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.Darks.dark6)
        public static let primaryInvertedConstant: Color = Primitives.Base.white
        public static let secondary: Color = .dynamic(light: Primitives.Darks.dark2, dark: Primitives.Lights.light5)
        public static let tertiary: Color = Primitives.Darks.dark1
    }

    enum Status {
        public static let accent: Color = Primitives.Blue.azure
        public static let disabled: Color = .dynamic(light: Primitives.Lights.light4, dark: Primitives.Darks.dark3)
        public static let warning: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
        public static let attention: Color = .dynamic(light: Primitives.Yellow.tangerine, dark: Primitives.Yellow.mustard)
        public static let positive: Color = Primitives.Green.eucalyptus
    }
}

// MARK: - Graphic

public extension Color.Tangem.Graphic {
    enum Neutral {
        public static let primary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Base.white)
        public static let primaryInverted: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.Darks.dark6)
        public static let primaryInvertedConstant: Color = Primitives.Base.white
        public static let secondary: Color = .dynamic(light: Primitives.Darks.dark2, dark: Primitives.Lights.light5)
        public static let tertiary: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Darks.dark2)
        public static let tertiaryConstant: Color = Primitives.Darks.dark1
        public static let quaternary: Color = .dynamic(light: Primitives.Lights.light4, dark: Primitives.Darks.dark3)
    }

    enum Status {
        public static let accent: Color = Primitives.Blue.azure
        public static let warning: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
        public static let attention: Color = .dynamic(light: Primitives.Yellow.tangerine, dark: Primitives.Yellow.mustard)
    }
}

// MARK: - Button

public extension Color.Tangem.Button {
    static let backgroundPrimary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Lights.light1)
    static let backgroundSecondary: Color = .dynamic(light: Primitives.darkAlpha.opacity(0.1), dark: Primitives.lightAlpha.opacity(0.1))
    static let backgroundDisabled: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark5)
    static let backgroundPositive: Color = Primitives.Blue.azure
    static let textPrimary: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
    static let textSecondary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Lights.light4)
    static let textDisabled: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Lights.light5)
    static let iconPrimary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Lights.light4)
    static let iconSecondary: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
    static let iconDisabled: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark5)
    static let borderPrimary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Lights.light4)
}

// MARK: - Surface

public extension Color.Tangem.Surface {
    static let level1: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.Darks.dark6)
    static let level2: Color = .dynamic(light: Primitives.Lights.light1, dark: Primitives.Base.black)
    static let level3: Color = .dynamic(light: Primitives.Lights.light1, dark: Primitives.Darks.dark6)
    static let level4: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.Darks.dark5)
}

// MARK: - Controls

public extension Color.Tangem.Controls {
    static let backgroundChecked: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Blue.azure)
    static let backgroundDefault: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
    static let iconDefault: Color = Primitives.Base.white
    static let iconDisabled: Color = Primitives.Base.white
}

// MARK: - Border

public extension Color.Tangem.Border {
    enum Neutral {
        public static let primary: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
        public static let secondary: Color = .dynamic(light: Primitives.Lights.light5, dark: Primitives.Darks.dark4)
    }

    enum Status {
        public static let accent: Color = Primitives.Blue.azure
        public static let warning: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
        public static let attention: Color = .dynamic(light: Primitives.Yellow.tangerine, dark: Primitives.Yellow.mustard)
    }
}

// MARK: - Field

public extension Color.Tangem.Field {
    static let backgroundDefault: Color = .dynamic(light: Primitives.Lights.light1, dark: Primitives.Darks.dark5)
    static let backgroundFocused: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
    static let textPlaceholder: Color = .dynamic(light: Primitives.Darks.dark2, dark: Primitives.Lights.light5)
    static let textDefault: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Base.white)
    static let textDisabled: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Darks.dark2)
    static let textInvalid: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
    static let borderInvalid: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
    static let iconDefault: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Darks.dark2)
    static let iconDisabled: Color = .dynamic(light: Primitives.Lights.light4, dark: Primitives.Darks.dark3)
}

// MARK: - Overlay

public extension Color.Tangem.Overlay {
    static let overlayPrimary: Color = Primitives.Overlays.overlay1
    static let overlaySecondary: Color = Primitives.Overlays.overlay2
}

// MARK: - Fill

public extension Color.Tangem.Fill {
    enum Neutral {
        public static let primary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Base.white)
        public static let primaryInverted: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.Darks.dark6)
        public static let primaryInvertedConstant: Color = Primitives.Base.white
        public static let secondary: Color = .dynamic(light: Primitives.Darks.dark2, dark: Primitives.Lights.light5)
        public static let tertiaryConstant: Color = Primitives.Darks.dark1
        public static let quaternary: Color = .dynamic(light: Primitives.Lights.light4, dark: Primitives.Darks.dark3)
    }

    enum Status {
        public static let accent: Color = Primitives.Blue.azure
        public static let warning: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
        public static let attention: Color = .dynamic(light: Primitives.Yellow.tangerine, dark: Primitives.Yellow.mustard)
    }
}

// MARK: - Skeleton

public extension Color.Tangem.Skeleton {
    static let backgroundPrimary: Color = .dynamic(light: Primitives.Lights.light1, dark: Primitives.Darks.dark5)
}

// MARK: - Markers

public extension Color.Tangem.Markers {
    static let backgroundSolidGray: Color = .dynamic(light: Primitives.Lights.light3, dark: Primitives.Darks.dark5)
    static let backgroundSolidBlue: Color = Primitives.Blue.azure
    static let backgroundSolidRed: Color = Primitives.Red.amaranth
    static let backgroundDisabled: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark5)
    static let textGray: Color = .dynamic(light: Primitives.Darks.dark2, dark: Primitives.Lights.light4)
    static let textBlue: Color = Primitives.Blue.azure
    static let textRed: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
    static let textDisabled: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Lights.light5)
    static let iconGray: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Darks.dark2)
    static let iconBlue: Color = Primitives.Blue.azure
    static let iconRed: Color = Primitives.Red.amaranth
    static let iconDisabled: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark5)
    static let borderGray: Color = .dynamic(light: Primitives.Lights.light3, dark: Primitives.lightAlpha.opacity(0.2))
    static let borderTintedBlue: Color = Primitives.Blue.azure.opacity(0.1)
    static let borderTintedRed: Color = Primitives.Red.amaranth.opacity(0.1)
    static let backgroundTintedBlue: Color = Primitives.Blue.azure.opacity(0.1)
    static let backgroundTintedRed: Color = Primitives.Red.amaranth.opacity(0.1)
    static let backgroundTintedGray: Color = .dynamic(light: Primitives.darkAlpha.opacity(0.1), dark: Primitives.lightAlpha.opacity(0.1))
}

// MARK: - Visa

public extension Color.Tangem.Visa {
    static let bannerGradientStart: Color = Primitives.Visa.bannerGradientStart
    static let cardDetailBackground: Color = Primitives.Visa.background
}

private extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        let uiColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        }
        return Color(uiColor: uiColor)
    }
}

// MARK: - Init with hex-value

public extension Color {
    init?(hex: String) {
        let r, g, b, a: Double

        var hexColor = hex.replacingOccurrences(of: "#", with: "")
        if hexColor.count == 6 {
            hexColor += "FF"
        }

        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            r = Double((hexNumber & 0xff000000) >> 24) / 255
            g = Double((hexNumber & 0x00ff0000) >> 16) / 255
            b = Double((hexNumber & 0x0000ff00) >> 8) / 255
            a = Double(hexNumber & 0x000000ff) / 255

            self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
            return
        }

        return nil
    }
}
