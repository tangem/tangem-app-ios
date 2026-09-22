//
//  StakingYieldFetchResult.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingYieldFetchResult {
    public let yield: StakingYieldInfo
    public let targets: [StakingTargetSummary]

    public init(yield: StakingYieldInfo, targets: [StakingTargetSummary]) {
        self.yield = yield
        self.targets = targets
    }
}
