//
//  StakingTargetSummary+Normalized.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

extension StakingTargetSummary {
    var normalized: StakingTargetSummary {
        return StakingTargetSummary(
            network: network,
            address: TransactionHistoryAddressNormalizer.normalize(address, networkID: network.rawValue),
            name: name
        )
    }
}
