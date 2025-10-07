//
//  YieldModuleAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol YieldModuleAPIService {
    func getYieldMarkets() async throws -> YieldModuleDTO.Response.MarketsInfo
    func getTokenPositionInfo(
        tokenContractAddress: String,
        chainId: Int
    ) async throws -> YieldModuleDTO.Response.PositionInfo
}
