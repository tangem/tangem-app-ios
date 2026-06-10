//
//  ExpressFeatureFlags.swift
//  TangemExpress
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressFeatureFlags {
    public let isApproveWithSwapEnabled: Bool

    public init(isApproveWithSwapEnabled: Bool) {
        self.isApproveWithSwapEnabled = isApproveWithSwapEnabled
    }
}
