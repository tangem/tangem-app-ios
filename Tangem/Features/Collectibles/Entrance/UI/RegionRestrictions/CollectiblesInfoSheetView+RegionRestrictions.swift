//
//  CollectiblesInfoSheetView+RegionRestrictions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

extension CollectiblesInfoSheetView.Model {
    static var regionRestrictions: Self {
        Self(
            icon: DesignSystem.Icons.Warning.regular28,
            iconColor: DesignSystem.Color.iconStatusWarning,
            iconBackgroundColor: DesignSystem.Color.bgStatusWarningSubtle,
            title: Localization.collectiblesRegionRestrictionsTitle,
            message: Localization.collectiblesRegionRestrictionsSubtitle,
            buttonTitle: Localization.commonClose
        )
    }
}

// MARK: - Previews

#Preview {
    CollectiblesInfoSheetView(model: .regionRestrictions, onClose: {})
}
