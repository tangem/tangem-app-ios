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
    struct Model: Hashable, Sendable {
        public let content: Content
        public let size: Size
        public let styleType: StyleType
        public let cornerStyle: CornerStyle
        public let horizontalLayout: HorizontalLayout
        public let isLoading: Bool
        public let action: @Sendable () -> Void

        public init(
            content: Content,
            size: Size = .x10,
            styleType: StyleType = .primary,
            cornerStyle: CornerStyle = .rounded,
            horizontalLayout: HorizontalLayout = .infinity,
            isLoading: Bool = false,
            action: @Sendable @escaping () -> Void
        ) {
            self.content = content
            self.size = size
            self.styleType = styleType
            self.cornerStyle = cornerStyle
            self.horizontalLayout = horizontalLayout
            self.isLoading = isLoading
            self.action = action
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(content)
            hasher.combine(size)
            hasher.combine(styleType)
            hasher.combine(cornerStyle)
            hasher.combine(horizontalLayout)
            hasher.combine(isLoading)
        }
    }
}

public extension TangemButton {
    enum CornerStyle: Equatable, Sendable {
        case rectangular
        case rounded
    }

    enum StyleType: Equatable, Sendable {
        case accent
        case primary
        case secondary
        case outline
        case ghost
        case primaryInverse
        case positive

        struct ColorScheme: Equatable, Sendable {
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

    enum ButtonState: Equatable, Sendable {
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

        public var isDisabled: Bool {
            if case .disabled = self {
                return true
            }
            return false
        }

        public var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }

        public var isNormal: Bool {
            if case .normal = self {
                return true
            }
            return false
        }
    }

    enum Content: Hashable, Sendable {
        case text(AttributedString)
        case icon(ImageType)
        case combined(
            text: AttributedString,
            icon: ImageType,
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

    enum Size: Sendable {
        case x15
        case x12
        case x11
        case x10
        case x9
        case x8
        case x7

        var height: CGFloat {
            switch self {
            case .x15: 60
            case .x12: 48
            case .x11: 44
            case .x10: 40
            case .x9: 36
            case .x8: 32
            case .x7: 28
            }
        }

        var font: Font {
            switch self {
            case .x7: .Tangem.Subheadline.medium.font
            case .x8, .x9, .x10, .x11, .x12, .x15: .Tangem.Body16.semibold.font
            }
        }

        var textStyle: Font.TextStyle {
            switch self {
            case .x7: .footnote
            case .x8, .x9, .x10, .x11, .x12, .x15: .body
            }
        }

        var horizontalInsets: CGFloat {
            switch self {
            case .x15, .x12: 24
            case .x11, .x10, .x9, .x8: 12
            case .x7: 8
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .x15: 16
            case .x12: 12
            case .x11, .x10, .x9, .x8, .x7: 8
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .x15, .x12: 28
            case .x11, .x10, .x9, .x8, .x7: 20
            }
        }
    }
}
