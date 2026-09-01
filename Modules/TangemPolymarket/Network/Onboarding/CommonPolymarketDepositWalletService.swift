//
//  CommonPolymarketDepositWalletService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

final class CommonPolymarketDepositWalletService {
    private let provider: TangemProvider<PolymarketDepositWalletTarget>
    private let environment: () -> PolymarketBFFEnvironment

    private let decoder = JSONDecoder()

    init(provider: TangemProvider<PolymarketDepositWalletTarget>, environment: @escaping () -> PolymarketBFFEnvironment) {
        self.provider = provider
        self.environment = environment
    }
}

// MARK: - PolymarketDepositWalletService protocol conformance

extension CommonPolymarketDepositWalletService: PolymarketDepositWalletService {
    func depositWalletState(
        ownerAddress: String?,
        walletId: String
    ) async throws(PolymarketWalletError) -> PolymarketDepositWallet {
        let response: PolymarketDTO.WalletStatusResponse = try await request(
            .walletState(ownerAddress: ownerAddress, walletId: walletId)
        )

        return PolymarketDepositWallet(
            address: response.depositWalletAddress,
            status: response.status
        )
    }

    func deployWallet(
        ownerAddress: String,
        depositWalletAddress: String,
        walletId: String
    ) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        let payload = PolymarketDTO.DeployRequest(
            ownerAddress: ownerAddress,
            depositWalletAddress: depositWalletAddress,
            walletId: walletId
        )

        let response: PolymarketDTO.WalletOperationResponse = try await request(.deploy(payload))
        return response.status
    }

    func submitApprovals(_ batch: PolymarketApprovalsBatch) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        let payload = PolymarketDTO.ApprovalsRequest(
            ownerAddress: batch.ownerAddress,
            depositWalletAddress: batch.depositWalletAddress,
            nonce: batch.nonce,
            deadline: batch.deadline,
            calls: batch.calls.map { PolymarketDTO.ApprovalCall(target: $0.target, value: $0.value, data: $0.data) },
            signature: batch.signature
        )

        let response: PolymarketDTO.WalletOperationResponse = try await request(.approvals(payload))
        return response.status
    }
}

// MARK: - Private implementation

private extension CommonPolymarketDepositWalletService {
    func request<T: Decodable>(_ target: PolymarketDepositWalletTarget.Target) async throws(PolymarketWalletError) -> T {
        let environment = environment()
        let request = PolymarketDepositWalletTarget(baseURL: environment.baseURL, target: target, headers: environment.headers)

        do {
            let response = try await provider.requestPublisher(request).async()
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            return try decoder.decode(T.self, from: filtered.data)
        } catch is CancellationError {
            throw PolymarketWalletError.cancelled
        } catch let error as MoyaError {
            throw PolymarketWalletError(apiError: CommonPolymarketAPIService.mapMoyaError(error, decoder: decoder))
        } catch {
            throw PolymarketWalletError(apiError: .connection(underlying: error))
        }
    }
}
