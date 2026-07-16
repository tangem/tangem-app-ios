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
        VStack(spacing: .unit(.x4)) {
            MultiWalletTokenItemsEmptyView()
                .iconColor(Color.Tangem.Graphic.Neutral.quaternary)
                .textColor(Color.Tangem.Text.Neutral.tertiary)
                .spacing(.unit(.x5))

            TangemButton(
                content: .text(AttributedString(Localization.commonAddTokens)),
                action: onManageTokensTap
            )
            .setStyleType(.secondary)
            .setSize(.x10)
            .setHorizontalLayout(.intrinsic)
        }
        .padding(.vertical, .unit(.x9))
    }
}
