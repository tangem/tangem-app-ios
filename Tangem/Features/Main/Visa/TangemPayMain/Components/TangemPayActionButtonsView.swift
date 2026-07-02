//
//  TangemPayActionButtonsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization
import TangemAccessibilityIdentifiers

struct TangemPayActionButtonsView: View {
    let actionButtonsDisabled: Bool
    let isWithdrawDisabled: Bool
    let addFundsAction: () -> Void
    let withdrawAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 40) {
            TangemMainActionButton(
                title: Localization.tangempayCardDetailsAddFunds,
                icon: DesignSystem.Icons.ArrowDown.regular16,
                action: addFundsAction
            )
            .disabled(actionButtonsDisabled)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.addFundsButton)

            TangemMainActionButton(
                title: Localization.tangempayCardDetailsWithdraw,
                icon: DesignSystem.Icons.ArrowUp.regular16,
                action: withdrawAction
            )
            .disabled(actionButtonsDisabled || isWithdrawDisabled)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.withdrawButton)
        }
    }
}

// MARK: - Previews

#Preview {
    TangemPayActionButtonsView(
        actionButtonsDisabled: false,
        isWithdrawDisabled: true,
        addFundsAction: {},
        withdrawAction: {}
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary)
}
