//
//  ExpressFeatureFlags.swift
//  TangemExpress
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressFeatureFlags {
    public let isApproveWithSwapEnabled: Bool
    public let isChooseBestDEXEnabled: Bool

    public init(isApproveWithSwapEnabled: Bool, isChooseBestDEXEnabled: Bool) {
        self.isApproveWithSwapEnabled = isApproveWithSwapEnabled
        self.isChooseBestDEXEnabled = isChooseBestDEXEnabled
    }
}
