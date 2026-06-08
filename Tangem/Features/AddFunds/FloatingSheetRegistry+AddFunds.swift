//
//  FloatingSheetRegistry+AddFunds.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerAddFundsFloatingSheets() {
        register(AddFundsViewModel.self) {
            AddFundsView(viewModel: $0)
        }
    }
}
