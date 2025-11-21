//
//  P2PStakingAPIService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

protocol P2PStakingAPIService {
    func getVaultsList() async throws -> P2PDTO.Vaults.VaultsInfo
    func getAccountSummary(
        delegatorAddress: String,
        vaultAddress: String
    ) async throws -> P2PDTO.AccountSummary.AccountSummaryInfo
    func getRewardsHistory(
        delegatorAddress: String,
        vaultAddress: String
    ) async throws -> P2PDTO.RewardsHistory.RewardsHistoryInfo
    func prepareDepositTransaction(
        request: P2PDTO.PrepareDepositTransaction.Request
    ) async throws -> P2PDTO.PrepareDepositTransaction.PrepareDepositTransactionInfo
    func prepareUnstakeTransaction(
        request: P2PDTO.PrepareUnstakeTransaction.Request
    ) async throws -> P2PDTO.PrepareUnstakeTransaction.PrepareUnstakeTransactionInfo
    func prepareWithdrawTransaction(
        request: P2PDTO.PrepareWithdrawTransaction.Request
    ) async throws -> P2PDTO.PrepareWithdrawTransaction.PrepareWithdrawTransactionInfo
    func broadcastTransaction(
        request: P2PDTO.BroadcastTransaction.Request
    ) async throws -> P2PDTO.BroadcastTransaction.BroadcastTransactionInfo
}
