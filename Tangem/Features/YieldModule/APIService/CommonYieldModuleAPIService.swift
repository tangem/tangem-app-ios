//
//  CommonYieldModuleAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

final class CommonYieldModuleAPIService {
    private let provider: TangemProvider<YieldModuleAPITarget>
    private let yieldModuleAPIType: YieldModuleAPIType

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }()

    init(provider: TangemProvider<YieldModuleAPITarget>, yieldModuleAPIType: YieldModuleAPIType) {
        assert(
            provider.plugins.contains(where: { $0 is YieldModuleAuthorizationPlugin }),
            "Should contains YieldModuleAuthorizationPlugin"
        )

        self.provider = provider
        self.yieldModuleAPIType = yieldModuleAPIType
    }
}

extension CommonYieldModuleAPIService: YieldModuleAPIService {
    func getYieldMarkets(
        chains: [String]?
    ) async throws -> YieldModuleDTO.Response.MarketsInfo {
        try await request(for: .markets(chains: chains), decoder: decoder)
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
}

private extension CommonYieldModuleAPIService {
    func request<T: Decodable>(for target: YieldModuleAPITarget.TargetType, decoder: JSONDecoder) async throws -> T {
        let request = YieldModuleAPITarget(yieldModuleAPIType: yieldModuleAPIType, target: target)
        let response = try await provider.asyncRequest(request)
        return try response.mapAPIResponseThrowingTangemAPIError(allowRedirectCodes: false, decoder: decoder)
    }
}
