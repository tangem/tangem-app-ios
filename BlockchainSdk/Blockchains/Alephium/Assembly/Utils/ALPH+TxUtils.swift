//
//  ALPH+TxUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

// MARK: - TxUtils

extension ALPH {
    struct TxUtils {
        private let dustUtxoAmount: ALPH.U256
        private let checkBuildUtils: CheckTxUtils
        private let calculateBuildUtils: CalculateTxUtils

        init(dustUtxoAmount: ALPH.U256) {
            self.dustUtxoAmount = dustUtxoAmount
            checkBuildUtils = CheckTxUtils(dustUtxoAmount: dustUtxoAmount)
            calculateBuildUtils = CalculateTxUtils(dustUtxoAmount: dustUtxoAmount)
        }

        // MARK: - Implementation

        func transfer(
            fromLockupScript: LockupScript,
            fromUnlockScript: UnlockScript,
            outputData: TxOutputInfo,
            gasOpt: GasBox,
            gasPrice: GasPrice,
            utxos: [AssetOutputInfo],
            networkId: NetworkId
        ) throws -> UnsignedTransaction {
            guard checkBuildUtils.checkTotalAttoAlphAmount(outputData.attoAlphAmount) else {
                throw TxError.alphAmountOverflow
            }

            let totalAmounts = try calculateTotalAmountNeeded(outputInfo: outputData)

            let (totalAmount, totalAmountPerToken, _) = totalAmounts

            let selected = try selectUTXOs(
                totalAmount: totalAmount,
                totalAmountPerToken: totalAmountPerToken,
                gasOpt: gasOpt,
                gasPrice: gasPrice,
                utxos: utxos
            )

            let unsignedTx = try buildTransferTx(
                fromLockupScript: fromLockupScript,
                fromUnlockScript: fromUnlockScript,
                inputs: selected.assets.map { ($0.ref, $0.output) },
                outputInfos: outputData,
                gas: selected.gas,
                gasPrice: gasPrice,
                networkId: networkId
            )

            return unsignedTx
        }

        // MARK: - Private Implementation

        private func selectUTXOs(
            totalAmount: U256,
            totalAmountPerToken: [(TokenId, U256)],
            gasOpt: GasBox,
            gasPrice: GasPrice,
            utxos: [AssetOutputInfo]
        ) throws -> ALPH.Selected {
            try ALPH.Build(
                providedGas: ProvidedGas(gasOpt: gasOpt, gasPrice: gasPrice, gasEstimationMultiplier: nil)
            )
            .select(
                amounts: ALPH.AssetAmounts(alph: totalAmount, tokens: totalAmountPerToken),
                utxos: utxos
            )
        }

        private func calculateTotalAmountNeeded(outputInfo: TxOutputInfo) throws -> (U256, [(TokenId, U256)], Int) {
            var totalAlphAmount = U256.zero
            var totalTokens: [TokenId: U256] = [:]
            var totalOutputLength = 0

            let tokenDustAmount = dustUtxoAmount.mulUnsafe(U256.unsafe(outputInfo.tokens.count))
            let outputLength = outputInfo.tokens.count + (outputInfo.attoAlphAmount <= tokenDustAmount ? 0 : 1)

            let alphAmount = max(outputInfo.attoAlphAmount, dustUtxoAmount.mulUnsafe(U256.unsafe(outputLength)))
            let newAlphAmount = totalAlphAmount.add(alphAmount) ?? U256.zero
            let newTotalTokens = try updateTokens(totalTokens, outputInfo.tokens).get()

            totalAlphAmount = newAlphAmount
            totalTokens = newTotalTokens
            totalOutputLength += outputLength

            let outputLengthSender = totalTokens.count // +1 не используется, как указано в комментарии в Kotlin-коде
            let alphAmountSender = dustUtxoAmount.mulUnsafe(U256.unsafe(outputLengthSender))
            let finalAlphAmount = totalAlphAmount.add(alphAmountSender) ?? U256.zero

            return (finalAlphAmount, Array(totalTokens), totalOutputLength + outputLengthSender)
        }

        private func updateTokens(
            _ totalTokens: [TokenId: U256],
            _ newTokens: [(TokenId, U256)]
        ) -> Result<[TokenId: U256], Error> {
            var result = totalTokens

            for (tokenId, amount) in newTokens {
                if let totalAmount = result[tokenId] {
                    if let newAmount = totalAmount.add(amount) {
                        result[tokenId] = newAmount
                    } else {
                        return .failure(TxError.alphAmountOverflow)
                    }
                } else {
                    result[tokenId] = amount
                }
            }

            return .success(result)
        }

        private func buildTransferTx(
            fromLockupScript: LockupScript,
            fromUnlockScript: UnlockScript,
            inputs: [(AssetOutputRef, AssetOutput)],
            outputInfos: TxOutputInfo,
            gas: GasBox,
            gasPrice: GasPrice,
            networkId: NetworkId
        ) throws -> UnsignedTransaction {
            let (txOutputs, changeOutputs) = try buildTxOutputs(
                fromLockupScript: fromLockupScript,
                inputs: inputs,
                outputInfos: outputInfos,
                gas: gas,
                gasPrice: gasPrice
            )

            return UnsignedTransaction(
                version: 0,
                networkId: networkId,
                gasAmount: gas,
                gasPrice: gasPrice,
                inputs: buildInputs(fromUnlockScript: fromUnlockScript, inputs: inputs),
                fixedOutputs: txOutputs + changeOutputs
            )
        }

        private func buildInputs(
            fromUnlockScript: UnlockScript,
            inputs: [(AssetOutputRef, AssetOutput)]
        ) -> [TxInputInfo] {
            return inputs.enumerated().map { index, pair in
                let (outputRef, _) = pair
                return index == 0 ? TxInputInfo(outputRef: outputRef, unlockScript: fromUnlockScript)
                    : TxInputInfo(outputRef: outputRef, unlockScript: SameAsPrevious())
            }
        }

        private func buildTxOutputs(
            fromLockupScript: LockupScript,
            inputs: [(AssetOutputRef, AssetOutput)],
            outputInfos: TxOutputInfo,
            gas: GasBox,
            gasPrice: GasPrice
        ) throws -> ([AssetOutput], [AssetOutput]) {
            let gasFeeResult = checkBuildUtils.preCheckBuildTx(inputs: inputs, gas: gas, gasPrice: gasPrice)

            switch gasFeeResult {
            case .failure(let error):
                throw error
            case .success(let gasFee):
                guard checkBuildUtils.checkMinimalAlphPerOutput(output: outputInfos) else {
                    throw NSError(domain: "TxError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Tx output value is too small"])
                }

                guard checkBuildUtils.checkTokenValuesNonZero(output: outputInfos) else {
                    throw NSError(domain: "TxError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Token values must be non-zero"])
                }

                let txOutputs = calculateBuildUtils.buildOutputs(outputInfo: outputInfos)

                let changeOutputsResult = try calculateBuildUtils.calculateChangeOutputs(
                    fromLockupScript: fromLockupScript,
                    inputs: inputs,
                    txOutputs: txOutputs,
                    gasFee: gasFee
                )

                switch changeOutputsResult {
                case .failure(let error):
                    throw error
                case .success(let changeOutputs):
                    return (txOutputs, changeOutputs)
                }
            }
        }
    }
}

// MARK: - Error

extension ALPH {
    enum TxError: Error {
        case alphAmountOverflow
        case runtime(String)
    }
}
