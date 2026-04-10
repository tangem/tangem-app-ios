//
//  FloatingSheetRegistry+AddTokenFlow.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerAddTokenFlowFloatingSheets() {
        register(AddTokenFlowViewModel.self) { flowViewModel in
            AddTokenFlowView(viewModel: flowViewModel)
        }
    }
}
