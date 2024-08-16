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
    func balances(wallet: StakingWallet) async throws -> [StakingBalanceInfo]

    func estimateStakeFee(request: ActionGenericRequest) async throws -> Decimal
    func estimateUnstakeFee(request: ActionGenericRequest) async throws -> Decimal
    func estimatePendingFee(request: ActionGenericRequest, type: PendingActionType) async throws -> Decimal

    func enterAction(request: ActionGenericRequest) async throws -> EnterAction
    func exitAction(request: ActionGenericRequest) async throws -> ExitAction
    func pendingAction(request: ActionGenericRequest, type: PendingActionType) async throws -> PendingAction

    func transaction(id: String) async throws -> StakingTransactionInfo
    func patchTransaction(id: String) async throws -> StakingTransactionInfo
    func submitTransaction(hash: String, signedTransaction: String) async throws
    func submitHash(hash: String, transactionId: String) async throws
}
