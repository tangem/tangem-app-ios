//
//  StakingUpdateSource.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum StakingUpdateSource {
    /// Single-wallet refresh (token details, staking details, send flows): per-address endpoints.
    case single
    /// Bulk portfolio refresh (initial login, main-screen pull-to-refresh): P2P uses the batched accounts endpoint.
    case batch
}
