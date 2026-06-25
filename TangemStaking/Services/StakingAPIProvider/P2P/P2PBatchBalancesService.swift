//
//  P2PBatchBalancesService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol P2PBatchBalancesService {
    /// Fetches staking balances for every Ethereum delegator address in a single batch request per vault.
    /// - Returns: a map keyed by lowercased delegator address; a missing key means no staking position.
    func balances() async throws -> [String: [StakingBalanceInfo]]
}
