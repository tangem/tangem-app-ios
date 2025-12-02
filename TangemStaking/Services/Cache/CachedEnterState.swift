//
//  CachedStakeState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum CachedStakeState: Codable, Hashable {
    case availableToStake
    case staked(balance: Decimal)
}
