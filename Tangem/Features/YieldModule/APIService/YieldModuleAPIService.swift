//
//  YieldModuleAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol YieldModuleAPIService {
    func getYieldMarkets(
        chainIDs: [String]?
    ) async throws -> YieldModuleDTO.Response.MarketsInfo
    func getTokenPositionInfo(
        tokenContractAddress: String,
        chainId: Int
    ) async throws -> YieldModuleDTO.Response.PositionInfo
    func getChart(
        tokenContractAddress: String,
        chainId: Int,
        window: YieldModuleDTO.ChartWindow?,
        bucketSizeDays: Int?
    ) async throws -> YieldModuleDTO.Response.Chart

    func activate(tokenContractAddress: String, walletAddress: String, chainId: Int, userWalletId: String) async throws
    func deactivate(tokenContractAddress: String, walletAddress: String, chainId: Int) async throws
    func sendTransactionEvent(txHash: String, operation: String) async throws
}

extension YieldModuleAPIService {
    func getYieldMarkets() async throws -> YieldModuleDTO.Response.MarketsInfo {
        try await getYieldMarkets(chainIDs: nil)
    }

    func getChart(
        tokenContractAddress: String,
        chainId: Int
    ) async throws -> YieldModuleDTO.Response.Chart {
        try await getChart(
            tokenContractAddress: tokenContractAddress,
            chainId: chainId,
            window: nil,
            bucketSizeDays: nil
        )
    }
}
