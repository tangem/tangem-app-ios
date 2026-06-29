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
    /// - Returns: a map keyed by lowercased delegator address. A missing key means the address has no staking
    ///   position *or* the endpoint returned a per-address error for it (e.g. an invalid delegator address) —
    ///   the two cases are not distinguished.
    func balances() async throws -> [String: [StakingBalanceInfo]]
}
