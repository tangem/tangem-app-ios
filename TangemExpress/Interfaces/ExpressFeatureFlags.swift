//
//  ExpressFeatureFlags.swift
//  TangemExpress
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressFeatureFlags {
    public let isRegionRestrictionsEnabled: Bool

    public init(isRegionRestrictionsEnabled: Bool = false) {
        self.isRegionRestrictionsEnabled = isRegionRestrictionsEnabled
    }
}
