//
//  CommonExpressFeatureFlagsProvider.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct CommonExpressFeatureFlagsProvider: ExpressFeatureFlagsProvider {
    var isApproveWithSwapEnabled: Bool {
        FeatureProvider.isAvailable(.approveFlowV2)
    }
}
