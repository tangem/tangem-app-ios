//
//  UIColor+.swift
//  TangemAssets
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

public extension UIColor {
    /// DO NOT remove this
    /// This is a UIColor from the new palette, used in UITextField's accessory view
    /// There's no good way to convert SwiftUI dynamic Color to UIColor and retain the dark/light appearance
    /// 👇👇👇 ------------------------------------ 👇👇👇
    @nonobjc static var backgroundPrimary: UIColor {
        return UIColor(named: "BackgroundPrimary", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var backgroundSecondary: UIColor {
        return UIColor(named: "BackgroundSecondary", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var backgroundPlain: UIColor {
        return UIColor(named: "BackgroundPlain", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var inputAccessoryViewTintColor: UIColor {
        return UIColor(named: "ButtonPrimary", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var textWarningColor: UIColor {
        return UIColor(named: "TextWarning", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var textAccent: UIColor {
        return UIColor(named: "TextAccent", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var textPrimary1: UIColor {
        return UIColor(named: "TextPrimary1", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var textDisabled: UIColor {
        return UIColor(named: "TextDisabled", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var iconInformative: UIColor {
        return UIColor(named: "IconInformative", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var iconAccent: UIColor {
        UIColor(named: "IconAccent", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var iconInactive: UIColor {
        UIColor(named: "IconInactive", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var iconWarning: UIColor {
        UIColor(named: "IconWarning", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var textTertiary: UIColor {
        UIColor(named: "TextTertiary", in: .module, compatibleWith: nil)!
    }

    // ☝️☝️☝️ End of UIColors from the new palette ☝️☝️☝️

    // MARK: Background

    @nonobjc static var tangemBg: UIColor {
        return UIColor(named: "tangem_bg", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var tangemGrayDark4: UIColor {
        return UIColor(named: "tangem_gray_dark4", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var tangemGrayDark6: UIColor {
        return UIColor(named: "tangem_gray_dark6", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var tangemBlue: UIColor {
        return UIColor(named: "tangem_blue", in: .module, compatibleWith: nil)!
    }

    @nonobjc static var tangemGrayDark: UIColor {
        return UIColor(named: "tangem_gray_dark", in: .module, compatibleWith: nil)!
    }
}

public extension UIColor {
    @available(iOS, deprecated: 18.0, message: "Replace with native 'Color.mix(with:by:in:)' if you are using this helper in SwiftUI only")
    func mix(with otherColor: UIColor, by fraction: CGFloat) -> UIColor {
        let clampedFraction = min(max(fraction, 0.0), 1.0)
        let invertedFraction = 1.0 - clampedFraction

        var components = (red: CGFloat(0.0), green: CGFloat(0.0), blue: CGFloat(0.0), alpha: CGFloat(0.0))
        var otherColorComponents = components // No COW for tuples`, but we don't care anyway

        getRed(
            &components.red,
            green: &components.green,
            blue: &components.blue,
            alpha: &components.alpha
        )

        otherColor.getRed(
            &otherColorComponents.red,
            green: &otherColorComponents.green,
            blue: &otherColorComponents.blue,
            alpha: &otherColorComponents.alpha
        )

        return UIColor(
            red: components.red * invertedFraction + otherColorComponents.red * clampedFraction,
            green: components.green * invertedFraction + otherColorComponents.green * clampedFraction,
            blue: components.blue * invertedFraction + otherColorComponents.blue * clampedFraction,
            alpha: components.alpha * invertedFraction + otherColorComponents.alpha * clampedFraction
        )
    }
}

public extension UIColor {
    var forcedLight: UIColor {
        resolvedColor(with: .dummyLight)
    }

    var forcedDark: UIColor {
        resolvedColor(with: .dummyDark)
    }
}

// MARK: - Private implementation

private extension UITraitCollection {
    /// - Warning: Dummy, do not use as a full-fledged trait collection instance.
    static let dummyLight = UITraitCollection(userInterfaceStyle: .light)
    /// - Warning: Dummy, do not use as a full-fledged trait collection instance.
    static let dummyDark = UITraitCollection(userInterfaceStyle: .dark)
}
