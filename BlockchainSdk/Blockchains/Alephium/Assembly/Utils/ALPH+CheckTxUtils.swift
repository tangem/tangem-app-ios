//
//  ALPH+CheckTxUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct CheckTxUtils {
        let dustUtxoAmount: U256

        // MARK: - Implementation

        func checkTotalAttoAlphAmount(_ amount: U256) -> Bool {
            amount <= ALPH.Constants.maxALPHValue
        }

        func checkWithMaxTxInputNum(assets: [(AssetOutputRef, AssetOutput)]) -> Bool {
            if assets.count > ALPH.Constants.maxTxInputNum {
                // Too many inputs for the transfer, consider reducing the amount to send, or use the `sweep-address` endpoint to consolidate the inputs first.
                return false
            }

            return true
        }

        func checkUniqueInputs(assets: [(AssetOutputRef, AssetOutput)]) -> Bool {
            let uniqueInputs = Set(assets.map { $0.0 })
            return assets.count == uniqueInputs.count
        }

        func preCheckBuildTx(
            inputs: [(AssetOutputRef, AssetOutput)],
            gas: GasBox,
            gasPrice: GasPrice
        ) -> Result<U256, Error> {
            guard gas >= Constants.minimalGasBox else {
                return .failure(TxError.runtime("gas < minimalGas"))
            }

            guard checkWithMaxTxInputNum(assets: inputs) else {
                return .failure(TxError.runtime("Too many inputs for the transfer"))
            }

            guard checkUniqueInputs(assets: inputs) else {
                return .failure(TxError.runtime("Inputs not unique"))
            }

            return .success(gasPrice * gas)
        }

        func checkMinimalAlphPerOutput(output: TxOutputInfo) -> Bool {
            if output.attoAlphAmount < dustUtxoAmount {
                // Tx output value is too small, avoid spreading dust
                return false
            }
            return true
        }

        func checkTokenValuesNonZero(output: TxOutputInfo) -> Bool {
            if output.tokens.contains(where: { $0.1.isZero }) {
                // Value is Zero for one or many tokens in the transaction output
                return false
            }
            return true
        }
    }
}
