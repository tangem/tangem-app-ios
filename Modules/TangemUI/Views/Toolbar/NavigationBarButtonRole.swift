//
//  NavigationBarButtonRole.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers

struct NavigationBarButtonRole {
    let sfSymbol: String
    let accessibilityIdentifier: String?

    static let back = NavigationBarButtonRole(
        sfSymbol: "chevron.backward",
        accessibilityIdentifier: CommonUIAccessibilityIdentifiers.backButton
    )

    static let close = NavigationBarButtonRole(
        sfSymbol: "xmark",
        accessibilityIdentifier: CommonUIAccessibilityIdentifiers.closeButton
    )

    static let add = NavigationBarButtonRole(
        sfSymbol: "plus",
        accessibilityIdentifier: CommonUIAccessibilityIdentifiers.addButton
    )

    static let share = NavigationBarButtonRole(
        sfSymbol: "square.and.arrow.up",
        accessibilityIdentifier: CommonUIAccessibilityIdentifiers.shareButton
    )

    static let details = NavigationBarButtonRole(
        sfSymbol: "ellipsis",
        accessibilityIdentifier: nil
    )

    /// Filled bell when subscribed, outline otherwise. Caller sets the accessibility identifier.
    static func priceAlert(isActive: Bool) -> NavigationBarButtonRole {
        NavigationBarButtonRole(
            sfSymbol: isActive ? "bell.fill" : "bell",
            accessibilityIdentifier: nil
        )
    }
}
