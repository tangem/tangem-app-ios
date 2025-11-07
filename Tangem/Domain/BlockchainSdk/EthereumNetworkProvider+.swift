//
//  EthereumNetworkProvider+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt

extension EthereumNetworkProvider {
    func getFee(
        gasLimit: BigUInt,
        supportsEIP1559: Bool,
        gasPrice: BigUInt? = nil
    ) async throws -> EthereumFeeParameters {
        let feeParameters = try await getFees(
            gasLimits: [gasLimit],
            supportsEIP1559: supportsEIP1559,
            gasPrice: gasPrice
        )
        guard let feeParameter = feeParameters.first else {
            throw BlockchainSdkError.failedToGetFee
        }

        return feeParameter
    }

    func getFees(
        gasLimits: [BigUInt],
        supportsEIP1559: Bool,
        gasPrice: BigUInt? = nil
    ) async throws -> [EthereumFeeParameters] {
        if supportsEIP1559 {
            let feeHistory = try await getFeeHistory().async()
            return eip1559FeeParameters(gasLimits: gasLimits, feeHistory: feeHistory)
        }

        if let gasPrice {
            return legacyFeeParameters(gasLimits: gasLimits, gasPrice: gasPrice)
        }

        let gasPrice = try await getGasPrice().async()
        return legacyFeeParameters(gasLimits: gasLimits, gasPrice: gasPrice)
    }

    private func eip1559FeeParameters(
        gasLimits: [BigUInt],
        feeHistory: EthereumFeeHistory
    ) -> [EthereumFeeParameters] {
        gasLimits.map {
            EthereumEIP1559FeeParameters(
                gasLimit: $0,
                baseFee: feeHistory.marketBaseFee,
                priorityFee: feeHistory.marketPriorityFee
            )
        }
    }

    private func legacyFeeParameters(
        gasLimits: [BigUInt],
        gasPrice: BigUInt
    ) -> [EthereumFeeParameters] {
        gasLimits.map {
            EthereumLegacyFeeParameters(
                gasLimit: $0,
                gasPrice: gasPrice
            )
        }
    }
}
