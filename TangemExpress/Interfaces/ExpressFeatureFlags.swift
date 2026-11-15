//
//  ExpressFeatureFlags.swift
//  TangemExpress
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressFeatureFlags {
    public let isAPIV2Enabled: Bool

    public init(
        isAPIV2Enabled: Bool
    ) {
        self.isAPIV2Enabled = isAPIV2Enabled
    }
}
