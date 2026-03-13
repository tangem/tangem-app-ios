//
//  View+navigationToolbar.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Redesigned Navigation Toolbar

public extension View {
    /// Adds a redesigned navigation toolbar with leading, principal and trailing content.
    /// On iOS 26+, uses native `.toolbar` with liquid glass support (enables `scrollEdgeEffect`).
    /// On iOS < 26, falls back to `safeAreaInset` with `VariableBlur`.
    @ViewBuilder
    func navigationToolbar(
        @ViewBuilder leadingContent: () -> some View,
        @ViewBuilder principalContent: () -> some View,
        @ViewBuilder trailingContent: () -> some View
    ) -> some View {
        if #available(iOS 26.0, *) {
            navigationLiquidGlassToolbar(
                leadingContent: leadingContent,
                principalContent: principalContent,
                trailingContent: trailingContent
            )
        } else {
            navigationFallbackToolbar(
                leadingContent: leadingContent,
                principalContent: principalContent,
                trailingContent: trailingContent
            )
        }
    }

    @available(iOS 26.0, *)
    private func navigationLiquidGlassToolbar(
        @ViewBuilder leadingContent: () -> some View,
        @ViewBuilder principalContent: () -> some View,
        @ViewBuilder trailingContent: () -> some View
    ) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarLeading, content: leadingContent)
                .sharedBackgroundVisibility(.hidden)

            ToolbarItem(placement: .principal, content: principalContent)
                .sharedBackgroundVisibility(.hidden)

            ToolbarItem(placement: .topBarTrailing, content: trailingContent)
                .sharedBackgroundVisibility(.hidden)
        }
    }

    private func navigationFallbackToolbar(
        @ViewBuilder leadingContent: () -> some View,
        @ViewBuilder principalContent: () -> some View,
        @ViewBuilder trailingContent: () -> some View
    ) -> some View {
        toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                NavigationHeader(
                    leadingContent: leadingContent,
                    principalContent: principalContent,
                    trailingContent: trailingContent
                )
            }
    }
}
