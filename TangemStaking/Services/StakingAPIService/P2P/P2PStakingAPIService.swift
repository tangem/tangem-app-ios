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
    func getVaultsList(network: String) async throws -> P2PDTO.Vaults.VaultsInfo
    func getAccountSummary(
        network: String,
        delegatorAddress: String,
        vaultAddress: String
    ) async throws -> P2PDTO.AccountSummary.AccountSummaryInfo
    func getRewardsHistory(
        network: String,
        delegatorAddress: String,
        vaultAddress: String
    ) async throws -> P2PDTO.RewardsHistory.RewardsHistoryInfo
    func prepareDepositTransaction(
        network: String,
        request: P2PDTO.PrepareDepositTransaction.Request
    ) async throws -> P2PDTO.PrepareDepositTransaction.PrepareDepositTransactionInfo
    func prepareUnstakeTransaction(
        network: String,
        request: P2PDTO.PrepareUnstakeTransaction.Request
    ) async throws -> P2PDTO.PrepareUnstakeTransaction.PrepareUnstakeTransactionInfo
    func prepareWithdrawTransaction(
        network: String,
        request: P2PDTO.PrepareWithdrawTransaction.Request
    ) async throws -> P2PDTO.PrepareWithdrawTransaction.PrepareWithdrawTransactionInfo
    func broadcastTransaction(
        network: String,
        request: P2PDTO.BroadcastTransaction.Request
    ) async throws -> P2PDTO.BroadcastTransaction.BroadcastTransactionInfo
}
