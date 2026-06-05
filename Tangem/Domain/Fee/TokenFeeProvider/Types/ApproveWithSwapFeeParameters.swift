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

/// Combined approve+swap fee parameters. Forwards the swap gas parameters to all
/// `EthereumFeeParameters` consumers (tx builder, gas-limit bumps, nonce analytics),
/// while carrying the approve component so it can't desync from the displayed total.
struct ApproveWithSwapFeeParameters: EthereumFeeParameters {
    let swapParameters: any EthereumFeeParameters
    /// Approve component with its own gas parameters — needed to build the approve tx at send.
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

    /// The swap component of the combined `total`: the approve part subtracted,
    /// the swap gas parameters attached.
    func swapFee(total: BSDKFee) -> BSDKFee {
        var swapAmount = total.amount
        swapAmount.value -= approveFee.amount.value
        return BSDKFee(swapAmount, parameters: swapParameters)
    }
}
