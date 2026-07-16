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
            DesignSystem.Font.bodyMediumToken
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
            case .brand: DesignSystem.Color.bgBrand
            case .default: DesignSystem.Color.bgInverse
            case .secondary: DesignSystem.Color.bgOpaquePrimary
            case .material: .clear
            case .outline: .clear
            case .ghost: .clear
            case .inverse: DesignSystem.Color.bgPrimary
            case .positive: DesignSystem.Color.bgStatusSuccess
            }
        }

        var foregroundColor: Color {
            switch self {
            case .brand, .positive:
                DesignSystem.Color.textStaticDarkPrimary

            case .default:
                DesignSystem.Color.textInversePrimary

            case .secondary, .material, .outline, .ghost, .inverse:
                DesignSystem.Color.textPrimary
            }
        }

        var borderColor: Color {
            switch self {
            case .outline:
                DesignSystem.Color.borderSecondary

            case .brand, .default, .secondary, .material, .ghost, .inverse, .positive:
                .clear
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .outline:
                1

            case .brand, .default, .secondary, .material, .ghost, .inverse, .positive:
                0
            }
        }

        var pressOverlay: Color {
            switch self {
            case .brand, .default, .positive:
                DesignSystem.Color.interactionPressStaticLight

            case .secondary, .material, .outline, .ghost, .inverse:
                DesignSystem.Color.interactionPress
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
