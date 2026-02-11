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
    let accessibilityIdentifier: String

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
}
