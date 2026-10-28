//
//  ExpressFeatureFlags.swift
//  TangemExpress
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressFeatureFlags {
    public let isSwapBestRateDefaultProviderEnabled: Bool
    public let isHideRejectedSwapProvidersEnabled: Bool

    public init(
        isSwapBestRateDefaultProviderEnabled: Bool,
        isHideRejectedSwapProvidersEnabled: Bool
    ) {
        self.isSwapBestRateDefaultProviderEnabled = isSwapBestRateDefaultProviderEnabled
        self.isHideRejectedSwapProvidersEnabled = isHideRejectedSwapProvidersEnabled
    }
}
