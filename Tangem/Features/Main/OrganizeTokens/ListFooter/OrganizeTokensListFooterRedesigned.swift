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

    private let buttonSize: TangemButtonV2.Size = .x12

    private var buttonsPadding: EdgeInsets {
        var contentInsets = contentInsets
        contentInsets.bottom += (hasBottomSafeAreaInset ? 6.0 : 12.0)
        return contentInsets
    }

    private var overlayViewTopPadding: CGFloat {
        return -max(75.0 - buttonsPadding.top - buttonSize.height, 0.0)
    }

    var body: some View {
        HStack(spacing: 8) {
            TangemButtonV2(
                label: Localization.commonCancel,
                accessibilityLabel: nil,
                action: actionsHandler.onCancelButtonTap
            )
            .styleType(.secondary)
            .size(buttonSize)
            .horizontalLayout(.infinity)
            .accessibilityIdentifier(OrganizeTokensAccessibilityIdentifiers.cancelButton)

            TangemButtonV2(
                label: Localization.commonApply,
                accessibilityLabel: nil,
                action: actionsHandler.onApplyButtonTap
            )
            .styleType(.default)
            .size(buttonSize)
            .horizontalLayout(.infinity)
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
            ListFooterOverlayShadowView(color: DesignSystem.Color.bgPrimary)
                .padding(.top, overlayViewTopPadding)
                .hidden(isTokenListFooterGradientHidden)
        )
    }
}

// MARK: - Previews

#Preview {
    struct PreviewHandler: OrganizeTokensListFooterActionsHandler {
        func onCancelButtonTap() {}
        func onApplyButtonTap() {}
    }

    return OrganizeTokensListFooterRedesigned(
        actionsHandler: PreviewHandler(),
        isTokenListFooterGradientHidden: false,
        contentInsets: EdgeInsets(top: 14, leading: 16, bottom: 0, trailing: 16)
    )
}
