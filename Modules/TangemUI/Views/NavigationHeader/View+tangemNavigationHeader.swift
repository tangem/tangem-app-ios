//
//  View+tangemNavigationHeader.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Adds a navigation header with Tangem icon on the left and a menu button on the right.
    /// Uses variable blur effect that fades from top (iOS < 26 only, as iOS 26+ uses native scrollEdgeEffect).
    func tangemNavigationHeader(
        trailingAction: @escaping () -> Void,
        accessibilityIdentifiers: TangemNavigationHeader.AccessibilityIdentifiers
    ) -> some View {
        modifier(TangemNavigationHeaderModifier(trailingAction: trailingAction, accessibilityIdentifiers: accessibilityIdentifiers))
    }
}

// MARK: - Modifier

private struct TangemNavigationHeaderModifier: ViewModifier {
    let trailingAction: () -> Void
    let accessibilityIdentifiers: TangemNavigationHeader.AccessibilityIdentifiers

    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                TangemNavigationHeader(trailingAction: trailingAction, accessibilityIdentifiers: accessibilityIdentifiers)
            }
    }
}
