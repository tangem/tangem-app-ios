//
//  FloatingSheetRegistry+AccountsAwareAddTokenFlow.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerAccountsAwareAddTokenFlowFloatingSheets() {
        register(AccountsAwareAddTokenFlowViewModel.self) { flowViewModel in
            AccountsAwareAddTokenFlowView(viewModel: flowViewModel)
        }
    }
}
