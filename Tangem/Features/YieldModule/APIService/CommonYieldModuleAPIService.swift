//
//  CommonYieldModuleAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

final class CommonYieldModuleAPIService {
    private let provider: TangemProvider<YieldModuleAPITarget>
    private let yieldModuleAPIType: YieldModuleAPIType
    private let tangemAPIType: TangemAPIType

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }()

    init(provider: TangemProvider<YieldModuleAPITarget>, yieldModuleAPIType: YieldModuleAPIType, tangemAPIType: TangemAPIType) {
        assert(
            provider.plugins.contains(where: { $0 is YieldModuleAuthorizationPlugin }),
            "Should contains YieldModuleAuthorizationPlugin"
        )

        self.provider = provider
        self.yieldModuleAPIType = yieldModuleAPIType
        self.tangemAPIType = tangemAPIType
    }
}

extension CommonYieldModuleAPIService: YieldModuleAPIService {
    func getYieldMarkets(
        chainIDs: [String]?
    ) async throws -> YieldModuleDTO.Response.MarketsInfo {
        try await request(for: .markets(chains: chainIDs), decoder: decoder)
    }

    func getIncentiveYieldMarkets(
        chainIDs: [String]?
    ) async throws -> YieldModuleDTO.Response.MarketsInfo {
        let enveloped: YieldModuleDTO.Enveloped<YieldModuleDTO.Response.MarketsInfo> = try await request(
            for: .incentiveMarkets(chains: chainIDs),
            decoder: decoder
        )
        return enveloped.result
    }

    func getIncentives(
        chainId: Int,
        userAddress: String
    ) async throws -> YieldModuleDTO.Response.IncentivesInfo? {
        try await incentivesRequest(for: .incentives(chainId: chainId, userAddress: userAddress))
    }

    func getClaimCalldata(
        chainId: Int,
        userAddress: String
    ) async throws -> YieldModuleDTO.Response.ClaimCalldata {
        let enveloped: YieldModuleDTO.Enveloped<YieldModuleDTO.Response.ClaimCalldata> = try await request(
            for: .claimCalldata(chainId: chainId, userAddress: userAddress),
            decoder: decoder
        )
        return enveloped.result
    }

    func getClaimHistory(
        chainId: Int,
        userAddress: String
    ) async throws -> YieldModuleDTO.Response.ClaimHistory? {
        try await incentivesRequest(for: .claimHistory(chainId: chainId, userAddress: userAddress))
    }

    func getAprHistory(
        chainId: Int,
        tokenAddress: String,
        days: Int
    ) async throws -> YieldModuleDTO.Response.AprHistory {
        let enveloped: YieldModuleDTO.Enveloped<YieldModuleDTO.Response.AprHistory> = try await request(
            for: .aprHistory(chainId: chainId, tokenAddress: tokenAddress, days: days),
            decoder: decoder
        )
        return enveloped.result
    }

    func getTokenPositionInfo(
        tokenContractAddress: String,
        chainId: Int
    ) async throws -> YieldModuleDTO.Response.PositionInfo {
        try await request(
            for: .token(
                tokenContractAddress: tokenContractAddress,
                chainId: chainId
            ),
            decoder: decoder
        )
    }

    func getChart(
        tokenContractAddress: String,
        chainId: Int,
        window: YieldModuleDTO.ChartWindow?,
        bucketSizeDays: Int?
    ) async throws -> YieldModuleDTO.Response.Chart {
        try await request(
            for: .chart(
                tokenContractAddress: tokenContractAddress,
                chainId: chainId,
                window: window?.rawValue,
                bucketSizeDays: bucketSizeDays
            ),
            decoder: decoder
        )
    }

    func activate(tokenContractAddress: String, walletAddress: String, chainId: Int, userWalletId: String) async throws {
        let _: YieldModuleDTO.Response.ActivateInfo = try await request(
            for: .activate(
                tokenContractAddress: tokenContractAddress,
                walletAddress: walletAddress,
                chainId: chainId,
                userWalletId: userWalletId
            ),
            decoder: decoder
        )
    }

    func deactivate(tokenContractAddress: String, walletAddress: String, chainId: Int) async throws {
        let _: YieldModuleDTO.Response.ActivateInfo = try await request(
            for: .deactivate(
                tokenContractAddress: tokenContractAddress,
                walletAddress: walletAddress,
                chainId: chainId
            ),
            decoder: decoder
        )
    }

    func sendTransactionEvent(txHash: String, operation: String, userAddress: String?) async throws {
        try await request(
            for: .transactionEvents(
                txHash: txHash,
                operation: operation,
                userAddress: userAddress,
            )
        )
    }
}

private extension CommonYieldModuleAPIService {
    func request<T: Decodable>(for target: YieldModuleAPITarget.TargetType, decoder: JSONDecoder) async throws -> T {
        try await response(for: target).mapAPIResponseThrowingTangemAPIError(allowRedirectCodes: false, decoder: decoder)
    }

    func request(for target: YieldModuleAPITarget.TargetType) async throws {
        _ = try await response(for: target)
    }

    func response(for target: YieldModuleAPITarget.TargetType) async throws -> Response {
        let request = YieldModuleAPITarget(yieldModuleAPIType: yieldModuleAPIType, tangemAPIType: tangemAPIType, target: target)

        return try await provider.asyncRequest(request)
    }

    /// The incentive surfaces answer with `unsupportedChainStatusCode` when the chain carries no campaign support,
    /// which the contract defines as a state rather than a failure. Endpoints that drive an action, claim calldata
    /// above all, must keep reporting it as an error.
    func incentivesRequest<T: Decodable>(for target: YieldModuleAPITarget.TargetType) async throws -> T? {
        let response = try await response(for: target)

        guard response.statusCode != Constants.unsupportedChainStatusCode else {
            return nil
        }

        let enveloped: YieldModuleDTO.Enveloped<T> = try response.mapAPIResponseThrowingTangemAPIError(
            allowRedirectCodes: false,
            decoder: decoder
        )

        return enveloped.result
    }

    enum Constants {
        static let unsupportedChainStatusCode = 400
    }
}
