//
//  FloatingSheetRegistry+MarketsRealAssets.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class TangemUI.FloatingSheetRegistry

extension FloatingSheetRegistry {
    func registerMarketsRealAssetsFloatingSheets() {
        register(MarketsRealAssetsFilterBottomSheetViewModel.self) { viewModel in
            MarketsRealAssetsFilterBottomSheetView(viewModel: viewModel)
        }
    }
}
