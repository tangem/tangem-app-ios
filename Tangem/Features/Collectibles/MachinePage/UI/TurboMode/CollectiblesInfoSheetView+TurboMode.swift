//
//  CollectiblesInfoSheetView+TurboMode.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

extension CollectiblesInfoSheetView.Model {
    static var turboMode: Self {
        Self(
            icon: DesignSystem.Icons.Info.regular28,
            iconColor: DesignSystem.Color.iconStatusInfo,
            iconBackgroundColor: DesignSystem.Color.bgStatusInfoSubtle,
            title: Localization.collectiblesTurboModeBottomsheetTitle,
            message: Localization.collectiblesTurboModeBottomsheetMessage,
            buttonTitle: Localization.commonGotIt
        )
    }
}

// MARK: - Previews

#Preview {
    CollectiblesInfoSheetView(model: .turboMode, onClose: {})
}
