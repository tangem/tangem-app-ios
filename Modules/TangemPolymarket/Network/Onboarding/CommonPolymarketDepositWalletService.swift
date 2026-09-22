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
    private let walletId: String

    private let decoder = JSONDecoder()

    init(
        provider: TangemProvider<PolymarketDepositWalletTarget>,
        environment: @escaping () -> PolymarketBFFEnvironment,
        walletId: String
    ) {
        self.provider = provider
        self.environment = environment
        self.walletId = walletId
    }
}

// MARK: - PolymarketDepositWalletService protocol conformance

extension CommonPolymarketDepositWalletService: PolymarketDepositWalletService {
    func depositWalletState(ownerAddress: String?) async throws(PolymarketWalletError) -> PolymarketDepositWallet {
        let response: PolymarketDTO.WalletStatusResponse = try await request(.walletState(ownerAddress: ownerAddress))

        return PolymarketDepositWallet(
            address: response.depositWalletAddress,
            status: response.status
        )
    }

    func deployWallet(
        ownerAddress: String,
        depositWalletAddress: String
    ) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        let payload = PolymarketDTO.DeployRequest(
            ownerAddress: ownerAddress,
            depositWalletAddress: depositWalletAddress,
            walletId: walletId
        )

        let response: PolymarketDTO.WalletOperationResponse = try await request(.deploy(payload))
        return response.status
    }

    func submitApprovals(_ batch: PolymarketRelayedBatch) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        let response: PolymarketDTO.WalletOperationResponse = try await request(
            .approvals(PolymarketDTO.RelayedBatchRequest(batch: batch))
        )
        return response.status
    }
}

// MARK: - Private implementation

private extension CommonPolymarketDepositWalletService {
    func request<T: Decodable>(_ target: PolymarketDepositWalletTarget.Target) async throws(PolymarketWalletError) -> T {
        let request = PolymarketDepositWalletTarget(environment: environment(), walletId: walletId, target: target)

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
