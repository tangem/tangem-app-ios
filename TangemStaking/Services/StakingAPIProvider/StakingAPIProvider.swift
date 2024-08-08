//
//  StakingAPIProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingAPIProvider {
    func enabledYields() async throws -> [YieldInfo]
    func yield(integrationId: String) async throws -> YieldInfo
    func balances(wallet: StakingWallet) async throws -> [StakingBalanceInfo]?

    func estimateStakeFee(amount: Decimal, address: String, validator: String, integrationId: String) async throws -> Decimal
    func estimateUnstakeFee(amount: Decimal, address: String, validator: String, integrationId: String) async throws -> Decimal
    func estimateClaimRewardsFee(
        amount: Decimal,
        address: String,
        validator: String,
        integrationId: String,
        passthrough: String
    ) async throws -> Decimal

    func enterAction(amount: Decimal, address: String, validator: String, integrationId: String) async throws -> EnterAction
    func exitAction(amount: Decimal, address: String, validator: String, integrationId: String) async throws -> ExitAction
    func pendingAction() async throws // [REDACTED_TODO_COMMENT]

    func transaction(id: String) async throws -> StakingTransactionInfo
    func patchTransaction(id: String) async throws -> StakingTransactionInfo
    func submitTransaction(hash: String, signedTransaction: String) async throws
    func submitHash(hash: String, transactionId: String) async throws
}
