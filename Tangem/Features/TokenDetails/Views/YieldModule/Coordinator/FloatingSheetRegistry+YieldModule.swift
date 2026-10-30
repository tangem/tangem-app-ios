//
//  FloatingSheetRegistry+YieldModule.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
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
            Group {
                if viewModel.usesIncentiveDesign {
                    YieldModuleAboutApyV2View(viewModel: viewModel)
                } else {
                    YieldModuleAboutApyView(viewModel: viewModel)
                }
            }
        }
    }
}
