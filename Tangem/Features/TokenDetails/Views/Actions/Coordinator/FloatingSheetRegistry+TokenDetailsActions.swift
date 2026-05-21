//
//  FloatingSheetRegistry+TokenDetailsActions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class TangemUI.FloatingSheetRegistry

extension FloatingSheetRegistry {
    func registerTokenDetailsActionsFloatingSheets() {
        register(TokenDetailsActionsBottomSheetViewModel.self) { viewModel in
            TokenDetailsActionsBottomSheetView(viewModel: viewModel)
        }
    }
}
