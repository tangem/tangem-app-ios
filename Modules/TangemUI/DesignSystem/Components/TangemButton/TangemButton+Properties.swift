//
//  TangemButton+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public extension TangemButton {
    enum CornerStyle: Equatable, Sendable {
        case `default`
        case rounded
    }

    enum StyleType: Equatable {
        case accent
        case primary
        case secondary
        case outline
        case ghost
        case primaryInverse
        case positive

        struct ColorScheme: Equatable {
            let background: Color
            let disabledBackground: Color
            let loadingOverlay: Color
            let pressedOverlay: Color

            init(
                background: Color,
                disabledBackground: Color = Color.Tangem.Button.backgroundDisabled,
                loadingOverlay: Color,
                pressedOverlay: Color
            ) {
                self.background = background
                self.disabledBackground = disabledBackground
                self.loadingOverlay = loadingOverlay
                self.pressedOverlay = pressedOverlay
            }
        }

        var strokeColor: Color {
            switch self {
            case .outline:
                return Color.Tangem.Border.Neutral.primary
            case .accent, .primary, .secondary, .ghost, .primaryInverse, .positive:
                return .clear
            }
        }

        var foregroundColor: Color {
            switch self {
            case .accent, .positive: Color.Tangem.Text.Neutral.primaryInvertedConstant
            case .primary: Color.Tangem.Text.Neutral.primaryInverted
            case .secondary, .outline, .ghost, .primaryInverse: Color.Tangem.Text.Neutral.primary
            }
        }

        var colorScheme: ColorScheme {
            switch self {
            case .accent:
                return .init(
                    background: Color.Tangem.Button.backgroundAccent,
                    loadingOverlay: Color.Tangem.Overlay.overlayPrimary,
                    pressedOverlay: Color.Tangem.Overlay.overlayPrimary
                )
            case .primary:
                return .init(
                    background: Color.Tangem.Button.backgroundPrimary,
                    loadingOverlay: Color.Tangem.Overlay.overlaySecondary,
                    pressedOverlay: Color.Tangem.Overlay.overlaySecondary
                )
            case .secondary:
                return .init(
                    background: Color.Tangem.Button.backgroundSecondary,
                    loadingOverlay: Color.Tangem.Overlay.overlayPrimary,
                    pressedOverlay: Color.Tangem.Button.backgroundSecondary
                )
            case .outline:
                return .init(
                    background: Color.Tangem.Surface.level1,
                    disabledBackground: Color.Tangem.Surface.level1,
                    loadingOverlay: .clear,
                    pressedOverlay: Color.Tangem.Surface.level1
                )
            case .ghost:
                return .init(
                    background: .clear,
                    loadingOverlay: .clear,
                    pressedOverlay: .clear
                )
            case .primaryInverse:
                return .init(
                    background: Color.Tangem.Button.backgroundPrimaryInverted,
                    loadingOverlay: Color.Tangem.Overlay.overlayPrimary,
                    pressedOverlay: Color.Tangem.Overlay.overlayPrimary
                )
            case .positive:
                return .init(
                    background: Color.Tangem.Button.backgroundPositive,
                    loadingOverlay: Color.Tangem.Overlay.overlayPrimary,
                    pressedOverlay: Color.Tangem.Overlay.overlayPrimary
                )
            }
        }
    }

    enum ButtonState: Equatable {
        case normal
        case disabled
        case loading

        public static func from(
            isLoading: Bool = false,
            isEnabled: Bool = true
        ) -> Self {
            if isLoading { return .loading }
            if !isEnabled { return .disabled }
            return .normal
        }

        var isDisabled: Bool {
            if case .disabled = self {
                return true
            }
            return false
        }

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }

        var isNormal: Bool {
            if case .normal = self {
                return true
            }
            return false
        }
    }

    enum Content: Equatable, Sendable {
        case text(AttributedString)
        case icon(Image)
        case combined(
            text: AttributedString,
            icon: Image,
            iconPosition: IconPosition
        )

        public enum IconPosition: Equatable, Sendable {
            case left
            case right
        }
    }

    enum HorizontalLayout: Equatable, Sendable {
        case intrinsic
        case infinity

        var maxWidth: CGFloat? {
            switch self {
            case .infinity: .infinity
            case .intrinsic: nil
            }
        }
    }

    enum Size {
        case x15
        case x12
        case x10
        case x9
        case x8
        case x7

        public var sizeUnit: SizeUnit {
            switch self {
            case .x15: return .x15
            case .x12: return .x12
            case .x10: return .x10
            case .x9: return .x9
            case .x8: return .x8
            case .x7: return .x7
            }
        }

        var height: CGFloat { sizeUnit.value }

        var font: Font {
            switch self {
            case .x7: Fonts.Regular.footnote
            case .x8, .x9, .x10, .x12, .x15: Fonts.Bold.body
            }
        }

        var textStyle: Font.TextStyle {
            switch self {
            case .x7: .footnote
            case .x8, .x9, .x10, .x12, .x15: .body
            }
        }

        var horizontalInsets: CGFloat {
            switch self {
            case .x15, .x12: SizeUnit.x6.value
            case .x10, .x9, .x8: SizeUnit.x3.value
            case .x7: SizeUnit.x2.value
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .x15: SizeUnit.x4.value
            case .x12: SizeUnit.x3.value
            case .x10, .x9, .x8, .x7: SizeUnit.x2.value
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .x15, .x12: SizeUnit.x7.value
            case .x10, .x9, .x8, .x7: SizeUnit.x5.value
            }
        }
    }
}
