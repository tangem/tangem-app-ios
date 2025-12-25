//
//  P2PStakingAPIService 2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

final class CommonP2PStakingAPIService: P2PStakingAPIService {
    private let provider: TangemProvider<P2PTarget>
    private let credential: StakingAPICredential
    private let network: P2PNetwork

    private lazy var millisecondsDateDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }()

    init(
        provider: TangemProvider<P2PTarget> = .init(),
        credential: StakingAPICredential,
        network: P2PNetwork
    ) {
        self.provider = provider
        self.credential = credential
        self.network = network
    }

    // MARK: - Vaults

    func getVaultsList() async throws -> P2PDTO.Vaults.VaultsInfo {
        try await response(.getVaultsList, decoder: millisecondsDateDecoder)
    }

    // MARK: - Account Summary

    func getAccountSummary(
        delegatorAddress: String,
        vaultAddress: String
    ) async throws -> P2PDTO.AccountSummary.AccountSummaryInfo {
        try await response(
            .getAccountSummary(delegatorAddress: delegatorAddress, vaultAddress: vaultAddress)
        )
    }

    // MARK: - Prepare Deposit Transaction

    func prepareDepositTransaction(
        request: P2PDTO.PrepareTransaction.Request
    ) async throws -> P2PDTO.PrepareTransaction.PrepareTransactionInfo {
        try await response(
            .prepareDepositTransaction(request: request)
        )
    }

    // MARK: - Prepare Unstake Transaction

    func prepareUnstakeTransaction(
        request: P2PDTO.PrepareTransaction.Request
    ) async throws -> P2PDTO.PrepareTransaction.PrepareTransactionInfo {
        try await response(
            .prepareUnstakeTransaction(request: request)
        )
    }

    // MARK: - Prepare Withdraw Transaction

    func prepareWithdrawTransaction(
        request: P2PDTO.PrepareTransaction.Request
    ) async throws -> P2PDTO.PrepareTransaction.PrepareTransactionInfo {
        try await response(
            .prepareWithdrawTransaction(request: request)
        )
    }

    // MARK: - Broadcast Transaction

    func broadcastTransaction(
        request: P2PDTO.BroadcastTransaction.Request
    ) async throws -> P2PDTO.BroadcastTransaction.BroadcastTransactionInfo {
        try await response(
            .broadcastTransaction(request: request)
        )
    }

    // MARK: - Private

    private func response<T: Decodable>(
        _ target: P2PTarget.Target,
        decoder: JSONDecoder? = nil
    ) async throws -> T {
        let targetType = P2PTarget(
            apiKey: credential.apiKey,
            target: target,
            network: network
        )
        let response = try await provider.requestPublisher(targetType).async()
        do {
            let decoder = decoder ?? self.decoder
            let p2pResponse = try decoder.decode(P2PDTO.GenericResponse<T>.self, from: response.data)

            if let result = p2pResponse.result {
                return result
            }

            if let error = p2pResponse.error {
                throw P2PStakingError.apiError(P2PAPIError(apiError: error))
            }

            throw P2PStakingError.httpError(statusCode: response.statusCode)
        } catch {
            StakingLogger.error(error: error)
            throw error
        }
    }
}
