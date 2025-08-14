//
//  View+style.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import CoreText

public extension View {
    func style(_ font: Font, color: Color) -> some View {
        self
            .font(font)
            .foregroundStyle(color)
            .lineHeight(font: font)
    }
}

extension Font {
    /// Получаем реальный UIFont для данного SwiftUI.Font с учётом Dynamic Type
    func toUIFont() -> UIFont {
        switch self {
        case .largeTitle: return UIFont.preferredFont(forTextStyle: .largeTitle)
        case .title: return UIFont.preferredFont(forTextStyle: .title1)
        case .title2: return UIFont.preferredFont(forTextStyle: .title2)
        case .title3: return UIFont.preferredFont(forTextStyle: .title3)
        case .headline: return UIFont.preferredFont(forTextStyle: .headline)
        case .body: return UIFont.preferredFont(forTextStyle: .body)
        case .callout: return UIFont.preferredFont(forTextStyle: .callout)
        case .subheadline: return UIFont.preferredFont(forTextStyle: .subheadline)
        case .footnote: return UIFont.preferredFont(forTextStyle: .footnote)
        case .caption: return UIFont.preferredFont(forTextStyle: .caption1)
        case .caption2: return UIFont.preferredFont(forTextStyle: .caption2)
        default: return UIFont.preferredFont(forTextStyle: .body)
        }
    }

    var preferredLineHeight: CGFloat {
        switch self {
        case .largeTitle: return 41
        case .title: return 34
        case .title2: return 28
        case .title3: return 25
        case .headline: return 22
        case .body: return 22
        case .callout: return 21
        case .subheadline: return 20
        case .footnote: return 18
        case .caption: return 16
        case .caption2: return 13
        default: return Font.body.preferredLineHeight
        }
    }
}

extension View {
    /// Задаём точную высоту строки через расчёт lineSpacing дельты
    func lineHeight(font: Font) -> some View {
        let uiFont = font.toUIFont()
        let delta = max(0, font.preferredLineHeight - uiFont.lineHeight)
        let scaledSize = UIFontMetrics.default.scaledValue(for: uiFont.pointSize)

        // frame(minHeight: scaledSize)
        return readGeometry(onChange: { viewSize in
            print(
                "->>",
                "lineHeight:", uiFont.lineHeight,
                "preferredLineHeight:", font.preferredLineHeight,
                "delta:", delta,
                "pointSize:", uiFont.pointSize,
                "scaledSize:", scaledSize,
                "viewSize:", viewSize.size
            )
        })
    }
}

@available(iOS 13, macCatalyst 13, tvOS 13, watchOS 6, *)
struct ScaledFont: ViewModifier {
//    [REDACTED_USERNAME](\.sizeCategory) var sizeCategory
    let name: String
    let size: Double

    func body(content: Content) -> some View {
        let scaledSize = UIFontMetrics.default.scaledValue(for: size)
        return content.font(.custom(name, size: scaledSize))
    }
}

@available(iOS 13, macCatalyst 13, tvOS 13, watchOS 6, *)
extension View {
    func scaledFont(name: String, size: Double) -> some View {
        return modifier(ScaledFont(name: name, size: size))
    }
}
