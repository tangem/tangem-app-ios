//
//  FloatingSheetRegistry+TokensManagement.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerTokensManagementFloatingSheets() {
        register(TokensManagementFlowViewModel.self) {
            TokensManagementFlowView(viewModel: $0)
        }
    }
}
