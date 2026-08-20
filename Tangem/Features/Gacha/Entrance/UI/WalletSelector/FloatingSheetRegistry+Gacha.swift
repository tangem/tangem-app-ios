//
//  FloatingSheetRegistry+Gacha.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerGachaFloatingSheets() {
        register(GachaWalletSelectorViewModel.self, viewBuilder: GachaWalletSelectorView.init)
    }
}
