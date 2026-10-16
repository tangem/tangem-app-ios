//
//  Button+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation

// MARK: - Content

public extension Button {
    enum Content: Hashable, Sendable {
        case label(AttributedString, iconStart: ImageType?, iconEnd: ImageType?)
        case iconOnly(ImageType)

        public static func label(_ text: AttributedString) -> Content {
            .label(text, iconStart: nil, iconEnd: nil)
        }
    }
}

// MARK: - Loading

public extension Button {
    enum Loading: Hashable, Sendable {
        case spinner
        case spinnerWithMessage(String)

        public static func spinner(if condition: Bool) -> Loading? {
            condition ? .spinner : nil
        }

        public static func spinnerWithMessage(_ message: String, if condition: Bool) -> Loading? {
            condition ? .spinnerWithMessage(message) : nil
        }

        var message: String? {
            switch self {
            case .spinner: nil
            case .spinnerWithMessage(let message): message
            }
        }
    }
}

// MARK: - Size

public extension Button {
    enum Size: Hashable, Sendable, CaseIterable {
        case x14
        case x12
        case x11
        case x10
        case x9
        case x8
        case x7

        public var height: CGFloat {
            switch self {
            case .x14: 56
            case .x12: 48
            case .x11: 44
            case .x10: 40
            case .x9: 36
            case .x8: 32
            case .x7: 28
            }
        }

        var labelMinWidth: CGFloat {
            switch self {
            case .x14: 88
            case .x12: 80
            case .x11: 72
            case .x10: 64
            case .x9: 56
            case .x8: 48
            case .x7: 40
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .x14: 16
            case .x12: 12
            case .x11: 12
            case .x10: 10
            case .x9: 8
            case .x8: 6
            case .x7: 6
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .x7:
                4

            case .x14, .x12, .x11, .x10, .x9, .x8:
                0
            }
        }

        /// Optical-compensation padding the design keeps wrapped around the label at all times,
        /// on top of the button's outer `horizontalPadding` — present whether or not icons are
        /// shown. Icons render outside this wrapper, so it doubles as the icon-to-label gap.
        var wrapperPadding: CGFloat {
            switch self {
            case .x14, .x12:
                8

            case .x11, .x10, .x9, .x8:
                6

            case .x7:
                4
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .x14, .x12:
                24

            case .x11, .x10, .x9, .x8:
                20

            case .x7:
                16
            }
        }

        var loaderSize: Loader.Size {
            switch self {
            case .x14, .x12:
                .size24

            case .x11, .x10, .x9, .x8:
                .size20

            case .x7:
                .size16
            }
        }

        var typographyToken: TangemTypographyToken {
            switch self {
            case .x7:
                DesignSystem.Font.subheadingMediumToken

            case .x14, .x12, .x11, .x10, .x9, .x8:
                DesignSystem.Font.bodyMediumToken
            }
        }
    }
}

// MARK: - Material

public extension Button {
    enum Material: Hashable, Sendable, CaseIterable {
        case glass
        case blur
    }
}

// MARK: - Appearance

public extension Button {
    enum Appearance: Hashable, Sendable, CaseIterable {
        case `default`
        case error
        case info

        var backgroundColor: Color {
            switch self {
            case .default: DesignSystem.Color.bgTransparentPrimary
            case .error: DesignSystem.Color.bgStatusErrorSubtle
            case .info: DesignSystem.Color.bgStatusInfoSubtle
            }
        }

        var foregroundColor: Color {
            switch self {
            case .default: DesignSystem.Color.textPrimary
            case .error: DesignSystem.Color.textStatusError
            case .info: DesignSystem.Color.textStatusInfo
            }
        }

        var pressOverlay: Color {
            switch self {
            case .default: DesignSystem.Color.interactionPressDefault
            case .error, .info: DesignSystem.Color.interactionPressInverse
            }
        }
    }
}

// MARK: - Style

public extension Button {
    enum StyleType: Hashable, Sendable {
        case brand
        case primary
        case secondary(Appearance)
        case material(Material)
        case outline
        case ghost
        case success

        var backgroundColor: Color {
            switch self {
            case .brand: DesignSystem.Color.bgBrand
            case .primary: DesignSystem.Color.bgInverse
            case .secondary(let appearance): appearance.backgroundColor
            case .material: .clear
            case .outline: .clear
            case .ghost: .clear
            case .success: DesignSystem.Color.bgStatusSuccess
            }
        }

        var foregroundColor: Color {
            switch self {
            case .brand, .success:
                DesignSystem.Color.textStaticDarkPrimary

            case .primary:
                DesignSystem.Color.textInversePrimary

            case .secondary(let appearance):
                appearance.foregroundColor

            case .material, .outline, .ghost:
                DesignSystem.Color.textPrimary
            }
        }

        var borderColor: Color {
            switch self {
            case .outline:
                DesignSystem.Color.borderSecondary

            case .brand, .primary, .secondary, .material, .ghost, .success:
                .clear
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .outline:
                1

            case .brand, .primary, .secondary, .material, .ghost, .success:
                0
            }
        }

        var pressOverlay: Color {
            switch self {
            case .brand, .primary, .success:
                DesignSystem.Color.interactionPressStaticLight

            case .secondary(let appearance):
                appearance.pressOverlay

            case .material, .outline, .ghost:
                DesignSystem.Color.interactionPressDefault
            }
        }

        var disabledStyle: DisabledStyle {
            switch self {
            case .brand, .primary, .success, .material:
                .swapColors

            case .secondary, .outline, .ghost:
                .dim
            }
        }
    }

    enum DisabledStyle: Hashable, Sendable {
        case swapColors
        case dim
    }
}

// MARK: - Horizontal layout

public extension Button {
    enum HorizontalLayout: Hashable, Sendable, CaseIterable {
        case intrinsic
        case infinity

        var maxWidth: CGFloat? {
            switch self {
            case .intrinsic: nil
            case .infinity: .infinity
            }
        }
    }
}

// MARK: - Model

public extension Button {
    struct Model: Hashable, Sendable {
        public let content: Content
        public let size: Size
        public let styleType: StyleType
        public let horizontalLayout: HorizontalLayout
        public let accessibilityLabel: String?
        @IgnoredEquatable
        public var action: @Sendable () -> Void

        public init(
            content: Content,
            accessibilityLabel: String?,
            size: Size = .x10,
            styleType: StyleType = .brand,
            horizontalLayout: HorizontalLayout = .intrinsic,
            action: @Sendable @escaping () -> Void
        ) {
            self.content = content
            self.accessibilityLabel = accessibilityLabel
            self.size = size
            self.styleType = styleType
            self.horizontalLayout = horizontalLayout
            self.action = action
        }
    }
}
