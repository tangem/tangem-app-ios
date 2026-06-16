//
//  P2PAPIProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol P2PAPIProvider {
    func yield(targetAmountLimitProvider: StakingTargetAmountLimitProvider?) async throws -> StakingYieldInfo
    func balances(walletAddress: String, vaults: [String]) async throws -> [StakingBalanceInfo]
    func stakeTransaction(
        walletAddress: String,
        vault: String,
        amount: Decimal
    ) async throws -> StakingTransactionInfo
    func unstakeTransaction(
        walletAddress: String,
        vault: String,
        amount: Decimal
    ) async throws -> StakingTransactionInfo
    func withdrawTransaction(
        walletAddress: String,
        vault: String,
        amount: Decimal
    ) async throws -> StakingTransactionInfo
    func broadcastTransaction(signedTransaction: String) async throws -> String
}
