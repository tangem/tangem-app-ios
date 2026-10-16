//
//  CollectiblesInfoSheetView+PackUnopened.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

extension CollectiblesInfoSheetView.Model {
    static func packUnopened(openPack: @escaping () -> Void) -> Self {
        Self(
            icon: DesignSystem.Icons.Warning.regular28,
            iconColor: DesignSystem.Color.iconStatusWarning,
            iconBackgroundColor: DesignSystem.Color.bgStatusWarningSubtle,
            title: Localization.collectiblesPackUnopenedTitle,
            message: Localization.collectiblesPackUnopenedSubtitle,
            primaryButton: Button(title: Localization.collectiblesPackUnopenedOpenPack, action: openPack)
        )
    }
}

// MARK: - Previews

#Preview {
    CollectiblesInfoSheetView(model: .packUnopened(openPack: {}), onClose: {}, onPrimary: {}, onSecondary: {})
}
