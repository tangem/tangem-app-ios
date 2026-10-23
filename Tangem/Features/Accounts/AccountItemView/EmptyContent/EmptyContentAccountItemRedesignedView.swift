//
//  EmptyContentAccountItemRedesignedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct EmptyContentAccountItemRedesignedView: View {
    let onManageTokensTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            MultiWalletTokenItemsEmptyView()
                .iconColor(DesignSystem.Color.iconTertiary)
                .textColor(DesignSystem.Color.textSecondary)
                .spacing(20)

            TangemUI.Button(
                label: Localization.commonAddTokens,
                accessibilityLabel: nil,
                action: onManageTokensTap
            )
            .styleType(.secondary(.default))
            .size(.x10)
            .horizontalLayout(.intrinsic)
        }
        .padding(.vertical, 36)
    }
}
