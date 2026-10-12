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
    /// Markets with the Merkl campaign overlay (`/yield-modules/markets`, enveloped response).
    func getIncentiveYieldMarkets(
        chainIDs: [String]?
    ) async throws -> YieldModuleDTO.Response.MarketsInfo
    /// `nil` when the chain is not supported or not configured for incentives, which the contract reports as HTTP 400.
    func getIncentives(
        chainId: Int,
        userAddress: String
    ) async throws -> YieldModuleDTO.Response.IncentivesInfo?
    /// Incentivised-yield history, ascending by date (`days` is capped at 90 by the contract).
    func getAprHistory(
        chainId: Int,
        tokenAddress: String,
        days: Int
    ) async throws -> YieldModuleDTO.Response.AprHistory
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

    /// Sends a transaction event to the backend.
    /// UserAddress is sent only if the user enabled push notifications, therefore optional.
    func sendTransactionEvent(txHash: String, operation: String, userAddress: String?) async throws
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
