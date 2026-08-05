//
//  FloatingSheetRegistry+ForYouAddFunds.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension FloatingSheetRegistry {
    func registerForYouAddFundsSheets() {
        register(ForYouAddFundsTokenSelectorViewModel.self) {
            ForYouAddFundsTokenSelectorView(viewModel: $0)
                .floatingSheetConfiguration(Self.apply)
        }
    }

    private static func apply(config: inout FloatingSheetConfiguration) {
        config.sheetBackgroundColor = DesignSystem.Color.bgPrimary
        config.backgroundInteractionBehavior = .tapToDismiss
    }
}
