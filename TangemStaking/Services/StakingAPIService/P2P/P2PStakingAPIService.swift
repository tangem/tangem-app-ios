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
    func prepareDepositTransaction(
        request: P2PDTO.PrepareTransaction.Request
    ) async throws -> P2PDTO.PrepareTransaction.PrepareTransactionInfo
    func prepareUnstakeTransaction(
        request: P2PDTO.PrepareTransaction.Request
    ) async throws -> P2PDTO.PrepareTransaction.PrepareTransactionInfo
    func prepareWithdrawTransaction(
        request: P2PDTO.PrepareTransaction.Request
    ) async throws -> P2PDTO.PrepareTransaction.PrepareTransactionInfo
    func broadcastTransaction(
        request: P2PDTO.BroadcastTransaction.Request
    ) async throws -> P2PDTO.BroadcastTransaction.BroadcastTransactionInfo
}
