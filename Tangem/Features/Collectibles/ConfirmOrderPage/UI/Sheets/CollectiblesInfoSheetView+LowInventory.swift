//
//  CollectiblesInfoSheetView+LowInventory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

extension CollectiblesInfoSheetView.Model {
    static func lowInventory(explorePacks: @escaping () -> Void, enableTurboMode: @escaping () -> Void) -> Self {
        Self(
            icon: DesignSystem.Icons.Error.regular28,
            iconColor: DesignSystem.Color.iconStatusError,
            iconBackgroundColor: DesignSystem.Color.bgStatusErrorSubtle,
            title: Localization.collectiblesLowInventoryTitle,
            message: Localization.collectiblesLowInventorySubtitle,
            primaryButton: Button(title: Localization.collectiblesLowInventoryExplorePacks, action: explorePacks),
            secondaryButton: Button(title: Localization.collectiblesLowInventoryEnableTurboMode, action: enableTurboMode)
        )
    }
}

// MARK: - Previews

#Preview {
    CollectiblesInfoSheetView(
        model: .lowInventory(explorePacks: {}, enableTurboMode: {}),
        onClose: {},
        onPrimary: {},
        onSecondary: {}
    )
}
