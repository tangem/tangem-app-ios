//
//  TangemPayMoneyAccountToolbarModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TangemPayMoneyAccountToolbarModifier: ViewModifier {
    let menuSections: [[TangemPayMoneyAccountMenuItem]]
    let onMenuItemSelected: (TangemPayMoneyAccountMenuItem) -> Void

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .translucentNavigationBar()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 4) {
                Text(Localization.virtualAccountTitle)
                    .font(token: DesignSystem.Font.bodyMediumToken)
                    .foregroundStyle(DesignSystem.Color.textPrimary)

                Text(Localization.tangempayUsdcOnPolygonNetwork)
                    .font(token: DesignSystem.Font.captionMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(Array(menuSections.enumerated()), id: \.offset) { _, menuItems in
                    Section {
                        ForEach(menuItems, id: \.self) { item in
                            SwiftUI.Button(
                                role: item.style.buttonRole,
                                action: { onMenuItemSelected(item) }
                            ) {
                                Text(item.title)

                                if let subtitle = item.subtitle {
                                    Text(subtitle)
                                }

                                item.image.image
                            }
                        }
                    }
                }
            } label: {
                DesignSystem.Icons.DotsVertical.regular20.image
            }
        }
    }
}

// MARK: - Button role

private extension TangemPayMoneyAccountMenuItem.Style {
    var buttonRole: ButtonRole? {
        switch self {
        case .normal: nil
        case .destructive: .destructive
        }
    }
}

// MARK: - Modificator Helper

extension View {
    func tangemPayMoneyAccountToolbar(
        menuSections: [[TangemPayMoneyAccountMenuItem]],
        onMenuItemSelected: @escaping (TangemPayMoneyAccountMenuItem) -> Void
    ) -> some View {
        modifier(
            TangemPayMoneyAccountToolbarModifier(
                menuSections: menuSections,
                onMenuItemSelected: onMenuItemSelected
            )
        )
    }
}
