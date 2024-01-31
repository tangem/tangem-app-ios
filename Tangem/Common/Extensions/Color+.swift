//
//  Color+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension Color {
    // MARK: Primary

    @nonobjc static var tangemGreen: Color {
        return Color("tangem_green")
    }

    // MARK: Complimentary

    @nonobjc static var tangemWarning: Color {
        return Color("tangem_warning")
    }

    @nonobjc static var tangemBlue: Color {
        return Color("tangem_blue")
    }

    @nonobjc static var tangemCritical: Color {
        return Color(.tangemCritical)
    }

    // MARK: Gray Dark

    @nonobjc static var tangemGrayDark1: Color {
        return Color("tangem_gray_dark_1")
    }

    @nonobjc static var tangemGrayDark: Color {
        return Color("tangem_gray_dark")
    }

    @nonobjc static var tangemGrayDark2: Color {
        return Color("tangem_gray_dark2")
    }

    @nonobjc static var tangemGrayDark3: Color {
        return Color("tangem_gray_dark3")
    }

    @nonobjc static var tangemGrayDark5: Color {
        return Color("tangem_gray_dark5")
    }

    @nonobjc static var tangemGrayDark6: Color {
        return Color("tangem_gray_dark6")
    }

    // MARK: Gray Light

    @nonobjc static var tangemGrayLight4: Color {
        return Color("tangem_gray_light4")
    }

    @nonobjc static var tangemGrayLight5: Color {
        return Color("tangem_gray_light5")
    }

    @nonobjc static var tangemGrayLight7: Color {
        return Color("tangem_gray_light7")
    }

    @nonobjc static var tangemSkeletonGray: Color {
        return Color("tangem_skeleton_gray")
    }

    @nonobjc static var tangemSkeletonGray2: Color {
        return Color("tangem_skeleton_gray2")
    }

    @nonobjc static var tangemSkeletonGray3: Color {
        return Color("tangem_skeleton_gray3")
    }

    @nonobjc static var tangemHoverButton: Color {
        return Color("tangem_btn_hover_bg")
    }

    // MARK: Background

    @nonobjc static var tangemBgGray: Color {
        return Color(.tangemBgGray)
    }

    @nonobjc static var tangemBgGray2: Color {
        return Color(.tangemBgGray2)
    }

    @nonobjc static var tangemBg: Color {
        return Color("tangem_bg")
    }
}

extension UIColor {
    // DO NOT remove this
    // This is a UIColor from the new palette, used in UITextField's accessory view
    // There's no good way to convert SwiftUI dynamic Color to UIColor and retain the dark/light appearance
    // 👇👇👇 ------------------------------------ 👇👇👇
    @nonobjc static var backgroundPrimary: UIColor {
        return UIColor(named: "BackgroundPrimary")!
    }

    @nonobjc static var inputAccessoryViewTintColor: UIColor {
        return UIColor(named: "ButtonPrimary")!
    }

    @nonobjc static var textWarningColor: UIColor {
        return UIColor(named: "TextWarning")!
    }

    @nonobjc static var textAccent: UIColor {
        return UIColor(named: "TextAccent")!
    }

    @nonobjc static var textPrimary1: UIColor {
        return UIColor(named: "TextPrimary1")!
    }

    @nonobjc static var textDisabled: UIColor {
        return UIColor(named: "TextDisabled")!
    }

    // ☝️☝️☝️ End of UIColors from the new palette ☝️☝️☝️

    // MARK: Background

    @nonobjc static var tangemBgGray: UIColor {
        return UIColor(named: "tangem_bg_gray")!
    }

    @nonobjc static var tangemBgGray2: UIColor {
        return UIColor(named: "tangem_bg_gray2")!
    }

    @nonobjc static var tangemBg: UIColor {
        return UIColor(named: "tangem_bg")!
    }

    @nonobjc static var tangemGrayDark4: UIColor {
        return UIColor(named: "tangem_gray_dark4")!
    }

    @nonobjc static var tangemGrayDark6: UIColor {
        return UIColor(named: "tangem_gray_dark6")!
    }

    @nonobjc static var tangemBlue: UIColor {
        return UIColor(named: "tangem_blue")!
    }

    @nonobjc static var tangemGrayDark: UIColor {
        return UIColor(named: "tangem_gray_dark")!
    }

    @nonobjc static var tangemCritical: UIColor {
        UIColor(named: "tangem_critical")!
    }

    @nonobjc static var iconAccent: UIColor {
        UIColor(named: "IconAccent")!
    }
}

public extension Color {
    init?(hex: String) {
        let r, g, b, a: Double

        var hexColor = hex.remove("#")
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
