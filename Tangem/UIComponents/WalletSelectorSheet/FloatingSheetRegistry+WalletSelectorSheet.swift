//
//  FloatingSheetRegistry+WalletSelectorSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerWalletSelectorSheet() {
        register(WalletSelectorSheetViewModel.self, viewBuilder: WalletSelectorSheetView.init)
    }
}
