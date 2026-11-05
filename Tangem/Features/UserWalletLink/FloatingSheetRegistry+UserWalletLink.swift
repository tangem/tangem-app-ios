//
//  FloatingSheetRegistry+UserWalletLink.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerUserWalletLinkFloatingSheets() {
        register(UserWalletLinkSheetViewModel.self) { viewModel in
            UserWalletLinkSheetView(viewModel: viewModel)
        }
    }
}
