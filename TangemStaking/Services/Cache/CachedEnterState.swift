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

    public var balance: Decimal {
        switch self {
        case .availableToStake: .zero
        case .staked(let balance): balance
        }
    }
}
