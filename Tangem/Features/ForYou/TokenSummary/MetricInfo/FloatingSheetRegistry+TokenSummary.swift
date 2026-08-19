//
//  FloatingSheetRegistry+TokenSummary.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerTokenSummaryFloatingSheets() {
        register(TokenSummaryMetricInfoViewModel.self) { viewModel in
            TokenSummaryMetricInfoView(viewModel: viewModel)
        }
    }
}
