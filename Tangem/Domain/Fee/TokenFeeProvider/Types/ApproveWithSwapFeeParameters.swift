//
//  ApproveWithSwapFeeParameters.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import enum BlockchainSdk.EthereumFeeParametersType
import protocol BlockchainSdk.EthereumFeeParameters

struct ApproveWithSwapFeeParameters: EthereumFeeParameters {
    let swapParameters: any EthereumFeeParameters
    let approveFee: BSDKFee

    var parametersType: EthereumFeeParametersType {
        swapParameters.parametersType
    }

    func changingGasLimit(to value: BigUInt) -> Self {
        ApproveWithSwapFeeParameters(
            swapParameters: swapParameters.changingGasLimit(to: value),
            approveFee: approveFee
        )
    }

    func calculateFee(decimalValue: Decimal) -> Decimal {
        swapParameters.calculateFee(decimalValue: decimalValue) + approveFee.amount.value
    }

    func swapFee(total: BSDKFee) -> BSDKFee {
        var swapAmount = total.amount
        swapAmount.value -= approveFee.amount.value
        return BSDKFee(swapAmount, parameters: swapParameters)
    }
}

// MARK: - Combining

extension ApproveWithSwapFeeParameters {
    static func combinedFee(swapFee: BSDKFee, approveFee: BSDKFee) throws -> BSDKFee {
        guard let swapParameters = swapFee.parameters as? any EthereumFeeParameters else {
            throw TokenFeeLoaderError.swapFeeParametersNotFound
        }

        var combinedAmount = swapFee.amount
        combinedAmount.value += approveFee.amount.value

        return BSDKFee(
            combinedAmount,
            parameters: ApproveWithSwapFeeParameters(swapParameters: swapParameters, approveFee: approveFee)
        )
    }
}
