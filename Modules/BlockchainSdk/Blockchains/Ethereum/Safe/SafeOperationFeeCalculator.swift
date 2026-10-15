//
//  SafeOperationFeeCalculator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// The arithmetic of a Safe operation's price, kept apart from the network reads so it can be pinned by tests.
enum SafeOperationFeeCalculator {
    static func fee(
        estimate: SafeInnerCallEstimate,
        state: SafeContractState,
        parameters: SafeOperationParameters
    ) -> Fee {
        let safeTxGas = estimate.gasLimit.increased(byPercent: parameters.safeTxGasBufferPercent)
        let coinGasPrice = estimate.gasPrice.increased(byPercent: parameters.gasPriceMarginPercent)
        let feeParameters = SafeTransactionFeeParameters(
            safeTxGas: safeTxGas,
            baseGas: parameters.baseGas + (state.isDeployed ? 0 : parameters.deployGas),
            gasPrice: parameters.gasToken.gasPrice(fromCoinGasPrice: coinGasPrice),
            gasToken: parameters.gasToken,
            refundReceiver: parameters.refundReceiver,
            isDeployed: state.isDeployed,
            nonce: state.nonce
        )
        let value = feeParameters.calculateFee(decimalValue: parameters.gasToken.blockchain.decimalValue)
        let feeAmount = parameters.gasToken.amount(value: value)

        return Fee(feeAmount, parameters: feeParameters)
    }
}
