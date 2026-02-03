//
//  View+tangemLogoNavigationToolbar.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public extension View {
    private var tangemLogo: some View {
        Assets.newTangemLogo.image
            .foregroundColor(Colors.Icon.primary1)
    }

    /// Adds a navigation toolbar with a Tangem logo at leading position.
    /// - Note: Applies a `smart` remove of iOS 26 glass effect and transition for logo.
    /// - Parameter trailingItem: content for the top trailing button.
    @ViewBuilder
    func tangemLogoNavigationToolbar(trailingItem: some View) -> some View {
        if #available(iOS 26.0, *) {
            liquidGlassToolbar(trailingItem: trailingItem)
        } else {
            regularToolbar(trailingItem: trailingItem)
        }
    }

    @available(iOS 26.0, *)
    private func liquidGlassToolbar(trailingItem: some View) -> some View {
        // [REDACTED_USERNAME], ToolbarItemPlacement.principal + ToolbarRole.editor is the trick to force leading placement
        // while avoiding rectangular glass transition glitch during navigation pop animation.
        // Absolutely cursed...
        toolbar {
            ToolbarItem(placement: .principal) {
                tangemLogo
            }
            .sharedBackgroundVisibility(.hidden)

            ToolbarItem(placement: .topBarTrailing) {
                trailingItem
            }
        }
        .toolbarRole(.editor)
    }

    private func regularToolbar(trailingItem: some View) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarLeading) {
                tangemLogo
            }

            ToolbarItem(placement: .topBarTrailing) {
                trailingItem
            }
        }
    }
}
