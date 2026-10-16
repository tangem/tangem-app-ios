//
//  TangemPayTransactionHistoryErrorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct TangemPayTransactionHistoryErrorView: View {
    let reloadAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            TangemUI.Button(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                accessibilityLabel: Localization.commonReload,
                action: reloadAction
            )
            .size(.x10)
            .styleType(.primary)

            Text(Localization.transactionHistoryErrorFailedToLoad)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 48)
    }
}
