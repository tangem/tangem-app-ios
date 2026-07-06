//
//  FloatingSheetRegistry+PriceAlerts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class TangemUI.FloatingSheetRegistry

extension FloatingSheetRegistry {
    func registerPriceAlertsFloatingSheets() {
        register(
            PriceAlertsViewModel.self,
            viewBuilder: PriceAlertsView.init
        )
    }
}
