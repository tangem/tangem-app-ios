//
//  WalletIconContent.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public enum WalletIconContent {
    case image(UIImage)
    case iconWithBackground(IconWithBackground)
}

public extension WalletIconContent {
    struct IconWithBackground: Sendable {
        public let icon: ImageType
        public let iconColor: Color
        public let backgroundColor: Color

        public init(icon: ImageType, iconColor: Color, backgroundColor: Color) {
            self.icon = icon
            self.iconColor = iconColor
            self.backgroundColor = backgroundColor
        }
    }
}

public extension WalletIconContent.IconWithBackground {
    static let mobileWallet = WalletIconContent.IconWithBackground(
        // [REDACTED_TODO_COMMENT]
        icon: DesignSystem.Icons.Cloud.filled16,
        iconColor: DesignSystem.Color.iconSecondary,
        backgroundColor: DesignSystem.Color.bgTransparentSecondary
    )
}
