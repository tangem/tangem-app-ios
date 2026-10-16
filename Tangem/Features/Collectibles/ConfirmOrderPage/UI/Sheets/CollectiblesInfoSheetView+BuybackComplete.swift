//
//  CollectiblesInfoSheetView+BuybackComplete.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

// [REDACTED_TODO_COMMENT]
extension CollectiblesInfoSheetView.Model {
    static func buybackComplete(
        amount: String?,
        price: String,
        explorePacks: @escaping () -> Void,
        openAgain: @escaping () -> Void
    ) -> Self {
        let soldMessage = "Your common card was bought back instantly."

        return Self(
            icon: DesignSystem.Icons.Checkmark.regular28,
            iconColor: DesignSystem.Color.iconStatusSuccess,
            iconBackgroundColor: DesignSystem.Color.bgStatusSuccessSubtle,
            title: "Buyback complete",
            message: amount.map { "\(soldMessage) +\($0) is in your balance" } ?? soldMessage,
            primaryButton: Button(title: "Open again for \(price)", action: openAgain),
            secondaryButton: Button(title: Localization.collectiblesLowInventoryExplorePacks, action: explorePacks)
        )
    }
}

// MARK: - Previews

#Preview {
    CollectiblesInfoSheetView(
        model: .buybackComplete(amount: "35.60 USDC", price: "50 USDC", explorePacks: {}, openAgain: {}),
        onClose: {},
        onPrimary: {},
        onSecondary: {}
    )
}
