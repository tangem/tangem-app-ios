//
//  StakingAPIProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakeKitAPIProvider {
    func enabledYields() async throws -> [StakingYieldInfo]
    func yield(integrationId: String) async throws -> StakingYieldInfo
    func balances(wallet: StakingWallet, integrationId: String) async throws -> [StakingBalanceInfo]
    func actions(wallet: StakingWallet) async throws -> [PendingAction]

    func estimateStakeFee(request: ActionGenericRequest) async throws -> Decimal
    func estimateUnstakeFee(request: ActionGenericRequest) async throws -> Decimal
    func estimatePendingFee(request: PendingActionRequest) async throws -> Decimal

    func enterAction(request: ActionGenericRequest) async throws -> EnterAction
    func exitAction(request: ActionGenericRequest) async throws -> ExitAction
    func pendingAction(request: PendingActionRequest) async throws -> PendingAction

    func transaction(id: String) async throws -> StakingTransactionInfo
    func patchTransaction(id: String) async throws -> StakingTransactionInfo
    func submitTransaction(hash: String, signedTransaction: String) async throws
    func submitHash(hash: String, transactionId: String) async throws
}
