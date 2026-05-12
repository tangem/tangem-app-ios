//
//  TangemButtonV2+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation

// MARK: - Content

public extension TangemButtonV2 {
    enum Content: Hashable, Sendable {
        case label(AttributedString, iconStart: ImageType?, iconEnd: ImageType?)
        case iconOnly(ImageType)

        public static func label(_ text: AttributedString) -> Content {
            .label(text, iconStart: nil, iconEnd: nil)
        }
    }
}

// MARK: - Size

public extension TangemButtonV2 {
    enum Size: Hashable, Sendable, CaseIterable {
        case x14
        case x12
        case x11
        case x10
        case x9
        case x8
        case x7

        var height: CGFloat {
            switch self {
            case .x14: DesignSystem.Tokens.Size.s700
            case .x12: DesignSystem.Tokens.Size.s600
            case .x11: DesignSystem.Tokens.Size.s550
            case .x10: DesignSystem.Tokens.Size.s500
            case .x9: DesignSystem.Tokens.Size.s450
            case .x8: DesignSystem.Tokens.Size.s400
            case .x7: DesignSystem.Tokens.Size.s350
            }
        }

        var labelMinWidth: CGFloat {
            switch self {
            case .x14: DesignSystem.Tokens.Size.s1100
            case .x12: DesignSystem.Tokens.Size.s1000
            case .x11: DesignSystem.Tokens.Size.s900
            case .x10: DesignSystem.Tokens.Size.s800
            case .x9: DesignSystem.Tokens.Size.s700
            case .x8: DesignSystem.Tokens.Size.s600
            case .x7: DesignSystem.Tokens.Size.s500
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .x14: DesignSystem.Tokens.Spacing.s200
            case .x12: DesignSystem.Tokens.Spacing.s150
            case .x11: DesignSystem.Tokens.Spacing.s150
            case .x10: DesignSystem.Tokens.Spacing.s125
            case .x9: DesignSystem.Tokens.Spacing.s100
            case .x8: DesignSystem.Tokens.Spacing.s075
            case .x7: DesignSystem.Tokens.Spacing.s075
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .x7:
                DesignSystem.Tokens.Spacing.s050

            case .x14, .x12, .x11, .x10, .x9, .x8:
                DesignSystem.Tokens.Spacing.none
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .x14, .x12:
                DesignSystem.Tokens.Size.s300

            case .x11, .x10, .x9, .x8:
                DesignSystem.Tokens.Size.s250

            case .x7:
                DesignSystem.Tokens.Size.s200
            }
        }

        var loaderSize: TangemLoader.Size {
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
            DesignSystem.Tokens.Font.Body.medium
        }
    }
}

// MARK: - Material

public extension TangemButtonV2 {
    enum Material: Hashable, Sendable, CaseIterable {
        case glass
        case blur
    }
}

// MARK: - Style

public extension TangemButtonV2 {
    enum StyleType: Hashable, Sendable {
        case brand
        case `default`
        case secondary
        case material(Material)
        case outline
        case ghost
        case inverse
        case positive

        var backgroundColor: Color {
            switch self {
            case .brand: DesignSystem.Tokens.Theme.Bg.brand
            case .default: DesignSystem.Tokens.Theme.Bg.inverse
            case .secondary: DesignSystem.Tokens.Theme.Bg.Opaque.primary
            case .material: .clear
            case .outline: .clear
            case .ghost: .clear
            case .inverse: DesignSystem.Tokens.Theme.Bg.primary
            case .positive: DesignSystem.Tokens.Theme.Bg.Status.success
            }
        }

        var foregroundColor: Color {
            switch self {
            case .brand, .positive:
                DesignSystem.Tokens.Theme.Text.StaticDark.primary

            case .default:
                DesignSystem.Tokens.Theme.Text.Inverse.primary

            case .secondary, .material, .outline, .ghost, .inverse:
                DesignSystem.Tokens.Theme.Text.primary
            }
        }

        var borderColor: Color {
            switch self {
            case .outline:
                DesignSystem.Tokens.Theme.Border.secondary

            case .brand, .default, .secondary, .material, .ghost, .inverse, .positive:
                .clear
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .outline:
                DesignSystem.Tokens.BorderWidth.sm

            case .brand, .default, .secondary, .material, .ghost, .inverse, .positive:
                DesignSystem.Tokens.BorderWidth.none
            }
        }

        var pressOverlay: Color {
            switch self {
            case .brand, .default, .positive:
                DesignSystem.Tokens.Theme.Interaction.pressStaticLight

            case .secondary, .material, .outline, .ghost, .inverse:
                DesignSystem.Tokens.Theme.Interaction.press
            }
        }
    }
}

// MARK: - Horizontal layout

public extension TangemButtonV2 {
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

public extension TangemButtonV2 {
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
