//
//  EthereumMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import BigInt
import TangemFoundation

// MARK: - EthereumErrorMapper

enum EthereumMapper {
    static func mapError(_ error: Error) -> Error {
        if let moyaError = error as? MoyaError,
           let responseData = moyaError.response?.data,
           let ethereumResponse = try? JSONDecoder().decode(JSONRPC.Response<String, JSONRPC.APIError>.self, from: responseData),
           let errorMessage = ethereumResponse.result.error?.message,
           errorMessage.contains("gas required exceeds allowance", ignoreCase: true) {
            return ETHError.gasRequiredExceedsAllowance
        }

        return error
    }

    static func mapBigUInt(_ response: String) throws -> BigUInt {
        guard let value = BigUInt(response.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseGasLimit
        }

        return value
    }

    static func mapInt(_ response: String) throws -> Int {
        guard let value = Int(response.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseGasLimit
        }

        return value
    }

    static func mapFeeHistory(_ response: EthereumFeeHistoryResponse) throws -> EthereumFeeHistory {
        guard !response.baseFeePerGas.isEmpty,
              !response.reward.isEmpty else {
            throw ETHError.failedToParseFeeHistory
        }

        // This is an actual baseFee for a pending block
        guard let pendingBaseFeeString = response.baseFeePerGas.last,
              pendingBaseFeeString != "0x0" else {
            throw ETHError.failedToParseFeeHistory
        }

        let pendingBaseFee = try mapBigUInt(pendingBaseFeeString)
        let marketBaseFee = pendingBaseFee * BigUInt(12) / BigUInt(10)
        let fastBaseFee = pendingBaseFee * BigUInt(15) / BigUInt(10)

        let lowRewards = response.reward.compactMap { $0[safe: 0] }
        let marketRewards = response.reward.compactMap { $0[safe: 1] }
        let fastRewards = response.reward.compactMap { $0[safe: 2] }

        let lowAverage = try mapAverageReward(lowRewards)
        let marketAverage = try mapAverageReward(marketRewards)
        let fastAverage = try mapAverageReward(fastRewards)

        let feeHistory = EthereumFeeHistory(
            baseFee: pendingBaseFee,
            lowBaseFee: pendingBaseFee,
            marketBaseFee: marketBaseFee,
            fastBaseFee: fastBaseFee,
            lowPriorityFee: lowAverage,
            marketPriorityFee: marketAverage,
            fastPriorityFee: fastAverage
        )

        return feeHistory
    }

    private static func mapAverageReward(_ rewards: [String]) throws -> BigUInt {
        let rewards = rewards.filter { $0 != "0x0" }

        guard !rewards.isEmpty else {
            throw ETHError.failedToParseFeeHistory
        }

        let sum = try rewards.map { try mapDecimal($0) }.reduce(0, +)
        let total = Decimal(rewards.count)
        let averageDecimal = (sum / total).rounded(roundingMode: .plain)

        guard averageDecimal > 0 else {
            throw ETHError.failedToParseFeeHistory
        }

        let average = EthereumUtils.mapToBigUInt(averageDecimal)
        return average
    }

    static func mapToEthereumEIP1559FeeResponse(gasLimit: BigUInt, feeHistory: EthereumFeeHistory) -> EthereumEIP1559FeeResponse {
        return EthereumEIP1559FeeResponse(
            gasLimit: gasLimit,
            fees: (
                low: .init(max: feeHistory.lowBaseFee + feeHistory.lowPriorityFee, priority: feeHistory.lowPriorityFee),
                market: .init(max: feeHistory.marketBaseFee + feeHistory.marketPriorityFee, priority: feeHistory.marketPriorityFee),
                fast: .init(max: feeHistory.fastBaseFee + feeHistory.fastPriorityFee, priority: feeHistory.fastPriorityFee)
            )
        )
    }

    static func mapToEthereumLegacyFeeResponse(gasPrice: BigUInt, gasLimit: BigUInt) -> EthereumLegacyFeeResponse {
        let minGasPrice = gasPrice
        let normalGasPrice = gasPrice * BigUInt(12) / BigUInt(10)
        let maxGasPrice = gasPrice * BigUInt(15) / BigUInt(10)

        return EthereumLegacyFeeResponse(
            gasLimit: gasLimit,
            lowGasPrice: minGasPrice,
            marketGasPrice: normalGasPrice,
            fastGasPrice: maxGasPrice
        )
    }

    static func mapFeeHistoryFallback(gasPrice: BigUInt) -> EthereumFeeHistory {
        let legacyResponse = mapToEthereumLegacyFeeResponse(gasPrice: gasPrice, gasLimit: BigUInt(0))

        let feeHistory = EthereumFeeHistory(
            baseFee: BigUInt(0),
            lowBaseFee: BigUInt(0),
            marketBaseFee: BigUInt(0),
            fastBaseFee: BigUInt(0),
            lowPriorityFee: legacyResponse.lowGasPrice,
            marketPriorityFee: legacyResponse.marketGasPrice,
            fastPriorityFee: legacyResponse.fastGasPrice
        )

        return feeHistory
    }

    private static func mapDecimal(_ response: String) throws -> Decimal {
        guard let value = UInt64(response.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseGasLimit
        }

        return Decimal(value)
    }
}
