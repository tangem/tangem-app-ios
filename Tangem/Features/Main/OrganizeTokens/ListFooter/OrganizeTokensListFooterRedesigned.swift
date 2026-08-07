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

    private let buttonSize: TangemButtonV2.Size = .x12

    private var buttonsPadding: EdgeInsets {
        var contentInsets = contentInsets
        contentInsets.bottom += 12.0
        return contentInsets
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
        .background(alignment: .bottom) {
            TangemFade(position: .bottom)
                .variant(.hard)
                .ignoresSafeArea(edges: .bottom)
                .hidden(isTokenListFooterGradientHidden)
        }
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
