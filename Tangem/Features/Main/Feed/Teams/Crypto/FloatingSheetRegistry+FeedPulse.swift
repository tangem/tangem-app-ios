//
//  FloatingSheetRegistry+FeedPulse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class TangemUI.FloatingSheetRegistry

extension FloatingSheetRegistry {
    func registerFeedPulseFloatingSheets() {
        register(PulseTagFilterBottomSheetViewModel.self) { viewModel in
            PulseTagFilterBottomSheetView(viewModel: viewModel)
        }

        register(MarketCapInfoBottomSheetViewModel.self) { viewModel in
            MarketCapInfoBottomSheetView(viewModel: viewModel)
        }
    }
}
