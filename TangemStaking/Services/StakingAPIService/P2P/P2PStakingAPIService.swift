//
//  P2PStakingAPIService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

final class P2PStakingAPIService {
    private let provider: TangemProvider<P2PTarget>
    private let credential: StakingAPICredential

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(provider: TangemProvider<P2PTarget> = .init(), credential: StakingAPICredential) {
        self.provider = provider
        self.credential = credential
    }

    // MARK: - Vaults

    func getVaultsList(network: String) async throws -> P2PDTO.Vaults.VaultsInfo {
        try await response(.getVaultsList(network: network))
    }

    // MARK: - Account Summary

    func getAccountSummary(
        network: String,
        delegatorAddress: String,
        vaultAddress: String
    ) async throws -> P2PDTO.AccountSummary.AccountSummaryInfo {
        try await response(
            .getAccountSummary(network: network, delegatorAddress: delegatorAddress, vaultAddress: vaultAddress)
        )
    }

    // MARK: - Rewards History

    func getRewardsHistory(
        network: String,
        delegatorAddress: String,
        vaultAddress: String
    ) async throws -> P2PDTO.RewardsHistory.RewardsHistoryInfo {
        try await response(
            .getRewardsHistory(network: network, delegatorAddress: delegatorAddress, vaultAddress: vaultAddress)
        )
    }

    // MARK: - Prepare Deposit Transaction

    func prepareDepositTransaction(
        network: String,
        request: P2PDTO.PrepareDepositTransaction.Request
    ) async throws -> P2PDTO.PrepareDepositTransaction.PrepareDepositTransactionInfo {
        try await response(
            .prepareDepositTransaction(network: network, request: request)
        )
    }

    // MARK: - Prepare Unstake Transaction

    func prepareUnstakeTransaction(
        network: String,
        request: P2PDTO.PrepareUnstakeTransaction.Request
    ) async throws -> P2PDTO.PrepareUnstakeTransaction.PrepareUnstakeTransactionInfo {
        try await response(
            .prepareUnstakeTransaction(network: network, request: request)
        )
    }

    // MARK: - Prepare Withdraw Transaction

    func prepareWithdrawTransaction(
        network: String,
        request: P2PDTO.PrepareWithdrawTransaction.Request
    ) async throws -> P2PDTO.PrepareWithdrawTransaction.PrepareWithdrawTransactionInfo {
        try await response(
            .prepareWithdrawTransaction(network: network, request: request)
        )
    }

    // MARK: - Broadcast Transaction

    func broadcastTransaction(
        network: String,
        request: P2PDTO.BroadcastTransaction.Request
    ) async throws -> P2PDTO.BroadcastTransaction.BroadcastTransactionInfo {
        try await response(
            .broadcastTransaction(network: network, request: request)
        )
    }

    // MARK: - Private

    private func response<T: Decodable>(_ target: P2PTarget) async throws -> T {
        let response = try await provider.requestPublisher(target).async()
        let filtered = try response.filterSuccessfulStatusCodes()
        let p2pResponse = try decoder.decode(P2PDTO.GenericResponse<T>.self, from: filtered.data)
        if let error = p2pResponse.error {
            throw P2PStakingAPIError.apiError(error)
        }
        return p2pResponse.result
    }
}

enum P2PStakingAPIError: Error {
    case apiError(P2PDTO.APIError)
}
