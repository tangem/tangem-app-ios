//
//  FloatingSheetRegistry+EarnModule.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class TangemUI.FloatingSheetRegistry

extension FloatingSheetRegistry {
    func registerEarnModuleFloatingSheets() {
        register(EarnNetworkFilterBottomSheetViewModel.self) { viewModel in
            EarnNetworkFilterBottomSheetViewRedesign(viewModel: viewModel)
        }

        register(EarnTypeFilterBottomSheetViewModel.self) { viewModel in
            EarnTypeFilterBottomSheetViewRedesign(viewModel: viewModel)
        }
    }
}
