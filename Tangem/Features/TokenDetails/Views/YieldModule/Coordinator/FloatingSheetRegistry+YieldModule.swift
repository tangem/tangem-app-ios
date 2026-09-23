//
//  FloatingSheetRegistry+YieldModule.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class TangemUI.FloatingSheetRegistry

extension FloatingSheetRegistry {
    func registerYieldModuleFloatingSheets() {
        register(YieldModuleStartViewModel.self) { viewModel in
            YieldModuleStartView(viewModel: viewModel)
        }

        register(YieldModuleTransactionViewModel.self) { viewModel in
            YieldModuleTransactionView(viewModel: viewModel)
        }

        register(YieldModuleAboutApyViewModel.self) { viewModel in
            YieldModuleAboutApyView(viewModel: viewModel)
        }
    }
}
