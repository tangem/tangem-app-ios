//
//  P2PAPIProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol P2PAPIProvider {
    func yield(network: String) async throws -> StakingYieldInfo
    func balances(wallet: StakingWallet, vaults: [String]) async throws -> [StakingBalanceInfo]
}
