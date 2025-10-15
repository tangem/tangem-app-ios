//
//  YieldModuleTokenInfoManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol YieldModuleTokenInfoManager {
    func fetchYieldTokenInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleTokenInfo
}

final class CommonYieldModuleTokenInfoManager {
    private let yieldModuleAPIService: YieldModuleAPIService

    init(yieldModuleAPIService: YieldModuleAPIService) {
        self.yieldModuleAPIService = yieldModuleAPIService
    }
}

extension CommonYieldModuleTokenInfoManager: YieldModuleTokenInfoManager {
    func fetchYieldTokenInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleTokenInfo {
        let position = try await yieldModuleAPIService.getTokenPositionInfo(tokenContractAddress: tokenContractAddress, chainId: chainId)

        return YieldModuleTokenInfo(
            isActive: position.isActive,
            apy: position.apy,
            maxFeeNative: position.maxFeeNative,
            maxFeeUSD: position.maxFeeUSD
        )
    }
}
