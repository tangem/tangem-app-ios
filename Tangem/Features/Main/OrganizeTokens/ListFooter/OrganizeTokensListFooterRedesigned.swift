//
//  OrganizeTokensListFooterRedesigned.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct OrganizeTokensListFooterRedesigned: View {
    let actionsHandler: OrganizeTokensListFooterActionsHandler
    let isTokenListFooterGradientHidden: Bool
    let contentInsets: EdgeInsets

    @State private var hasBottomSafeAreaInset = false

    private let buttonSize: TangemButton.Size = .x12

    private var buttonsPadding: EdgeInsets {
        var contentInsets = contentInsets
        contentInsets.bottom += (hasBottomSafeAreaInset ? 6.0 : 12.0)
        return contentInsets
    }

    private var overlayViewTopPadding: CGFloat {
        return -max(75.0 - buttonsPadding.top - buttonSize.sizeUnit.value, 0.0)
    }

    var body: some View {
        HStack(spacing: .unit(.x2)) {
            TangemButton(
                content: .text(AttributedString(Localization.commonCancel)),
                action: actionsHandler.onCancelButtonTap
            )
            .setStyleType(.secondary)
            .setSize(buttonSize)
            .setCornerStyle(.rounded)
            .setHorizontalLayout(.infinity)
            .background(.regularMaterial, in: Capsule())
            .accessibilityIdentifier(OrganizeTokensAccessibilityIdentifiers.cancelButton)

            TangemButton(
                content: .text(AttributedString(Localization.commonApply)),
                action: actionsHandler.onApplyButtonTap
            )
            .setStyleType(.primary)
            .setSize(buttonSize)
            .setCornerStyle(.rounded)
            .setHorizontalLayout(.infinity)
            .accessibilityIdentifier(OrganizeTokensAccessibilityIdentifiers.applyButton)
        }
        .padding(buttonsPadding)
        .readGeometry(\.safeAreaInsets.bottom) { [oldValue = hasBottomSafeAreaInset] bottomInset in
            let newValue = bottomInset != 0.0
            if newValue != oldValue {
                hasBottomSafeAreaInset = newValue
            }
        }
        .background(
            ListFooterOverlayShadowView(color: Color.Tangem.Surface.level2)
                .padding(.top, overlayViewTopPadding)
                .hidden(isTokenListFooterGradientHidden)
        )
    }
}

// MARK: - Previews

#if DEBUG
private struct PreviewHandler: OrganizeTokensListFooterActionsHandler {
    func onCancelButtonTap() {}
    func onApplyButtonTap() {}
}

#Preview {
    OrganizeTokensListFooterRedesigned(
        actionsHandler: PreviewHandler(),
        isTokenListFooterGradientHidden: false,
        contentInsets: EdgeInsets(top: 14, leading: 16, bottom: 0, trailing: 16)
    )
}
#endif // DEBUG
