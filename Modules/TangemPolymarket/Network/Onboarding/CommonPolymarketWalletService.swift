//
//  CommonPolymarketWalletService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

final class CommonPolymarketWalletService {
    private let provider: TangemProvider<PolymarketWalletTarget>
    private let baseURL: URL

    private let decoder = JSONDecoder()

    init(provider: TangemProvider<PolymarketWalletTarget>, baseURL: URL) {
        self.provider = provider
        self.baseURL = baseURL
    }
}

// MARK: - PolymarketWalletService protocol conformance

extension CommonPolymarketWalletService: PolymarketWalletService {
    func walletState(ownerAddress: String) async throws(PolymarketWalletError) -> PolymarketWalletState {
        let response: PolymarketDTO.WalletStatusResponse = try await request(.walletState(ownerAddress: ownerAddress))

        return PolymarketWalletState(
            depositWalletAddress: response.depositWalletAddress,
            status: response.status
        )
    }

    func deployWallet(
        ownerAddress: String,
        depositWalletAddress: String,
        walletId: String
    ) async throws(PolymarketWalletError) -> PolymarketWalletStatus {
        let payload = PolymarketDTO.DeployRequest(
            ownerAddress: ownerAddress,
            depositWalletAddress: depositWalletAddress,
            walletId: walletId
        )

        let response: PolymarketDTO.WalletOperationResponse = try await request(.deploy(payload))
        return response.status
    }

    func submitApprovals(_ batch: PolymarketApprovalsBatch) async throws(PolymarketWalletError) -> PolymarketWalletStatus {
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

private extension CommonPolymarketWalletService {
    func request<T: Decodable>(_ target: PolymarketWalletTarget.Target) async throws(PolymarketWalletError) -> T {
        let request = PolymarketWalletTarget(baseURL: baseURL, target: target)

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
