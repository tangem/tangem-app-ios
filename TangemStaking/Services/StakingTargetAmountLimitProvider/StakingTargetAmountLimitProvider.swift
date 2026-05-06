//
//  StakingTargetAmountLimitProvider.swift
//  TangemStaking
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingTargetAmountLimitProvider: Sendable {
    func limit(forTargetAddress address: String) async -> Decimal?
}
