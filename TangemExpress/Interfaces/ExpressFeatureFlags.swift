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
    public let isAPIV2Enabled: Bool

    public init(
        isSwapBestRateDefaultProviderEnabled: Bool,
        isHideRejectedSwapProvidersEnabled: Bool,
        isAPIV2Enabled: Bool
    ) {
        self.isSwapBestRateDefaultProviderEnabled = isSwapBestRateDefaultProviderEnabled
        self.isHideRejectedSwapProvidersEnabled = isHideRejectedSwapProvidersEnabled
        self.isAPIV2Enabled = isAPIV2Enabled
    }
}
