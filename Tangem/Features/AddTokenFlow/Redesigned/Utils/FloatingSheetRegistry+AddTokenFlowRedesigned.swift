//
//  FloatingSheetRegistry+AddTokenFlowRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerAddTokenFlowRedesignedFloatingSheets() {
        register(AddTokenFlowRedesignedViewModel.self) { flowViewModel in
            AddTokenFlowRedesignedView(viewModel: flowViewModel)
        }
    }
}
