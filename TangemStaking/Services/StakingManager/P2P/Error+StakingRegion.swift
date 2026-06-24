//
//  Error+StakingRegion.swift
//  TangemStaking
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension Error {
    /// A 451 from the p2p API can arrive raw or wrapped in `StakingAvailabilityError.dataUnavailable`
    /// (the yield path wraps it when no target amount limits are cached).
    var isStakingRegionUnavailable: Bool {
        if let error = self as? P2PStakingError, case .regionUnavailable = error {
            return true
        }

        if let error = self as? StakingAvailabilityError,
           case .dataUnavailable(let underlying) = error,
           let underlyingP2P = underlying as? P2PStakingError,
           case .regionUnavailable = underlyingP2P {
            return true
        }

        return false
    }
}
