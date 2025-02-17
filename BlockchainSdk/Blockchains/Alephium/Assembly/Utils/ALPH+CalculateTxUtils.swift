//
//  ALPH+CalculateTxUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension ALPH {
    struct CalculateTxUtils {
        // MARK: - Properties

        let dustUtxoAmount: ALPH.U256

        // MARK: - Implementation

        func buildOutputs(outputInfo: TxOutputInfo) -> [AssetOutput] {
            let toLockupScript = outputInfo.lockupScript
            let attoAlphAmount = outputInfo.attoAlphAmount
            let tokens = outputInfo.tokens
            let lockTimeOpt = outputInfo.lockTime ?? TimeStamp.zero
            let additionalDataOpt = outputInfo.additionalData ?? Data()

            let tokenOutputs = tokens.map { token in
                AssetOutput(
                    amount: dustUtxoAmount,
                    lockupScript: toLockupScript,
                    lockTime: lockTimeOpt,
                    tokens: [token],
                    additionalData: additionalDataOpt
                )
            }

            let beforeSubtracting = U256(BigUInt(dustUtxoAmount.v * BigUInt(tokens.count)))
            let alphRemaining = attoAlphAmount.sub(beforeSubtracting) ?? U256.zero

            if alphRemaining == U256.zero {
                return tokenOutputs
            } else {
                let alphOutput = AssetOutput(
                    amount: max(alphRemaining, dustUtxoAmount),
                    lockupScript: toLockupScript,
                    lockTime: lockTimeOpt,
                    tokens: [],
                    additionalData: additionalDataOpt
                )
                return tokenOutputs + [alphOutput]
            }
        }

        func calculateChangeOutputs(
            fromLockupScript: LockupScript,
            inputs: [(AssetOutputRef, AssetOutput)],
            txOutputs: [AssetOutput],
            gasFee: U256
        ) throws -> Result<[AssetOutput], Error> {
            let inputUTXOView = inputs.map { $0.1 }

            let alphRemainder = try calculateAlphRemainder(
                inputs: inputUTXOView.map { $0.amount },
                outputs: txOutputs.map { $0.amount },
                gasFee: gasFee
            ).get()

            let tokensRemainder = try calculateTokensRemainder(
                inputsIn: inputUTXOView.flatMap { $0.tokens },
                outputsIn: txOutputs.flatMap { $0.tokens }
            ).get()

            return calculateChangeOutputs(
                alphRemainder: alphRemainder,
                tokensRemainder: tokensRemainder,
                fromLockupScript: fromLockupScript
            )
        }

        func calculateChangeOutputs(
            alphRemainder: U256,
            tokensRemainder: [(TokenId, U256)],
            fromLockupScript: LockupScript
        ) -> Result<[AssetOutput], Error> {
            guard alphRemainder != U256.zero || !tokensRemainder.isEmpty else {
                return .success([])
            }

            let tokenDustAmount = U256(dustUtxoAmount.v * BigUInt(tokensRemainder.count))
            let totalDustAmount = tokenDustAmount.v + dustUtxoAmount.v

            switch alphRemainder {
            case let x where x == tokenDustAmount || x >= tokenDustAmount:
                return .success(
                    buildOutputs(
                        outputInfo: TxOutputInfo(
                            lockupScript: fromLockupScript,
                            attoAlphAmount: alphRemainder,
                            tokens: tokensRemainder,
                            lockTime: nil,
                            additionalData: nil
                        )
                    )
                )

            case _ where tokensRemainder.isEmpty:
                return .failure(TxError.runtime(
                    "Not enough ALPH for ALPH change output, expected \(dustUtxoAmount), got \(alphRemainder)"
                ))

            case _ where alphRemainder < tokenDustAmount:
                return .failure(TxError.runtime(
                    "Not enough ALPH for token change output, expected \(tokenDustAmount), got \(alphRemainder)"
                ))

            default:
                return .failure(TxError.runtime(
                    "Not enough ALPH for ALPH and token change output, expected \(totalDustAmount), got \(alphRemainder)"
                ))
            }
        }

        private func calculateAlphRemainder(
            inputs: [U256],
            outputs: [U256],
            gasFee: U256
        ) -> Result<U256, Error> {
            var inputSum = U256.zero
            for sum in inputs {
                guard let newSum = inputSum.add(sum) else {
                    return .failure(TxError.runtime("Input amount overflow"))
                }
                inputSum = newSum
            }

            var outputAmount = U256.zero

            for sum in outputs {
                guard let newAmount = outputAmount.add(sum) else {
                    return .failure(TxError.runtime("Output amount overflow"))
                }
                outputAmount = newAmount
            }

            guard let remainder0 = inputSum.sub(outputAmount) else {
                return .failure(TxError.runtime("Not enough balance"))
            }

            guard let remainder = remainder0.sub(gasFee) else {
                return .failure(TxError.runtime("Not enough balance for gas fee"))
            }

            return .success(remainder)
        }

        private func calculateTokensRemainder(
            inputsIn: [(TokenId, U256)],
            outputsIn: [(TokenId, U256)]
        ) throws -> Result<[(TokenId, U256)], Error> {
            let inputs = try calculateTotalAmountPerToken(tokens: inputsIn).get()
            let outputs = try calculateTotalAmountPerToken(tokens: outputsIn).get()

            try checkNoNewTokensInOutputs(inputs: inputs, outputs: outputs).get()

            let remainder = try calculateRemainingTokens(inputTokens: inputs, outputTokens: outputs).get()

            return .success(remainder.filter { $0.1 != U256.zero })
        }

        private func calculateRemainingTokens(
            inputTokens: [(TokenId, U256)],
            outputTokens: [(TokenId, U256)]
        ) -> Result<[(TokenId, U256)], Error> {
            return .success(
                inputTokens.reduce(into: [(TokenId, U256)]()) { acc, input in
                    let (inputId, inputAmount) = input
                    let outputAmount = outputTokens.first { $0.0 == inputId }?.1 ?? U256.zero
                    guard let remainder = inputAmount.sub(outputAmount) else {
                        return acc.append((inputId, inputAmount))
                    }
                    acc.append((inputId, remainder))
                }
            )
        }

        private func calculateTotalAmountPerToken(
            tokens: [(TokenId, U256)]
        ) -> Result<[(TokenId, U256)], Error> {
            return .success(
                tokens.reduce(into: [(TokenId, U256)]()) { acc, token in
                    let (id, amount) = token
                    if let index = acc.firstIndex(where: { $0.0 == id }) {
                        guard let newAmount = acc[index].1.add(amount) else {
                            return acc.append((id, amount))
                        }
                        acc[index] = (id, newAmount)
                    } else {
                        acc.append((id, amount))
                    }
                }
            )
        }

        private func checkNoNewTokensInOutputs(
            inputs: [(TokenId, U256)],
            outputs: [(TokenId, U256)]
        ) -> Result<Void, Error> {
            let newTokens = Set(outputs.map { $0.0 }).subtracting(inputs.map { $0.0 })
            return newTokens.isEmpty ? .success(()) : .failure(TxError.runtime("New tokens found in outputs: \(newTokens)"))
        }
    }
}
