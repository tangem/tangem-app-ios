//
//  FloatingSheetRegistry+Collectibles.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerCollectiblesFloatingSheets() {
        register(CollectiblesAddFundsSheetViewModel.self, viewBuilder: CollectiblesAddFundsSheetView.FloatingSheet.init)
    }
}
