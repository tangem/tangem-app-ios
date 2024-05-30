//
//  StakingAvailabilityProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingAvailabilityProvider: Actor {
    func isAvailableForStaking(item: StakingTokenItem) async throws -> Bool
}
