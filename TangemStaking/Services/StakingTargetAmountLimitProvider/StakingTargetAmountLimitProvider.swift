//
//  StakingTargetAmountLimitProvider.swift
//  TangemStaking
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingTargetAmountLimitInfo: Sendable {
    public let limit: Decimal?
    public let coefficient: Decimal?

    public init(limit: Decimal?, coefficient: Decimal?) {
        self.limit = limit
        self.coefficient = coefficient
    }
}

public protocol StakingTargetAmountLimitProvider: Sendable {
    func snapshot() async -> [String: StakingTargetAmountLimitInfo]
}
