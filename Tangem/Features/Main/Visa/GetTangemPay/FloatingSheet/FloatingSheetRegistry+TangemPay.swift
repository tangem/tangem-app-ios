//
//  FloatingSheetRegistry+TangemPay.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

/// Just because of deeplinking doesn't embed with SUI Navigation
/// but instead uses UIKit, environment values like floatingSheetPresenter
/// does not works at all, because of floatingSheetRegistry would be missed on concrete CoordinatorView
public extension FloatingSheetRegistry {
    func registerTangemPayWalletSelectorSheets() {
        register(TangemPayWalletSelectorViewModel.self) {
            TangemPayWalletSelectorProxyView(viewModel: $0)
        }
    }
}
