//
//  StakingTargetType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public enum StakingTargetType: Hashable {
    /// In the case when there is a validator on the balance
    case target(StakingTargetInfo)

    /// In the case when there is a validator on the balance that has been disabled
    case disabled

    /// In the case when the balance / action doesn't have a validator
    case empty

    public var target: StakingTargetInfo? {
        switch self {
        case .target(let validatorInfo): validatorInfo
        case .disabled, .empty: nil
        }
    }
}
