//
//  NavigationBarButtonRole.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import TangemAssets

struct NavigationBarButtonRole {
    let sfSymbol: String
    let iconAsset: ImageType
    let accessibilityIdentifier: String?

    static let back = NavigationBarButtonRole(
        sfSymbol: "chevron.backward",
        iconAsset: Assets.Glyphs.chevron20LeftButtonNew,
        accessibilityIdentifier: CommonUIAccessibilityIdentifiers.backButton
    )

    static let close = NavigationBarButtonRole(
        sfSymbol: "xmark",
        iconAsset: Assets.Glyphs.cross20ButtonNew,
        accessibilityIdentifier: CommonUIAccessibilityIdentifiers.closeButton
    )

    static let add = NavigationBarButtonRole(
        sfSymbol: "plus",
        iconAsset: Assets.plus24,
        accessibilityIdentifier: CommonUIAccessibilityIdentifiers.addButton
    )

    static let share = NavigationBarButtonRole(
        sfSymbol: "square.and.arrow.up",
        iconAsset: Assets.DesignSystem.share,
        accessibilityIdentifier: CommonUIAccessibilityIdentifiers.shareButton
    )

    static let details = NavigationBarButtonRole(
        sfSymbol: "ellipsis",
        iconAsset: Assets.verticalDots,
        accessibilityIdentifier: nil
    )

    /// Filled bell when subscribed, outline otherwise. Caller sets the accessibility identifier.
    static func priceAlert(isActive: Bool) -> NavigationBarButtonRole {
        NavigationBarButtonRole(
            sfSymbol: isActive ? "bell.fill" : "bell",
            iconAsset: DesignSystem.Icons.Bell.regular24,
            accessibilityIdentifier: nil
        )
    }
}
