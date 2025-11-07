//
//  FloatingSheetRegistry+Markets.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerMarketsFloatingSheets() {
        register(MarketsTokenAccountNetworkSelectorFlowViewModel.self) { flowViewModel in
            MarketsTokenAccountNetworkSelectorFlowView(viewModel: flowViewModel)
        }
    }
}
