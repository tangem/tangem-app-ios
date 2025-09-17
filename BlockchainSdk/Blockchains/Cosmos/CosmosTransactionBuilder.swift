//
//  CosmosTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import TangemFoundation

class CosmosTransactionBuilder {
    private let publicKey: Data
    private let cosmosChain: CosmosChain
    private var sequenceNumber: UInt64?
    private var accountNumber: UInt64?

    init(publicKey: Data, cosmosChain: CosmosChain) throws {
        assert(
            PublicKey.isValid(data: publicKey, type: .secp256k1),
            "CosmosTransactionBuilder received invalid public key"
        )

        self.publicKey = publicKey
        self.cosmosChain = cosmosChain
    }

    func setSequenceNumber(_ sequenceNumber: UInt64) {
        self.sequenceNumber = sequenceNumber
    }

    func setAccountNumber(_ accountNumber: UInt64) {
        self.accountNumber = accountNumber
    }

    // MARK: Regular transaction

    func buildForSign(transaction: Transaction) throws -> Data {
        let txInputData = try makeInput(transaction: transaction, fee: transaction.fee)
        return try buildForSignRaw(txInputData: txInputData)
    }

    func buildForSend(transaction: Transaction, signature: Data) throws -> Data {
        let txInputData = try makeInput(transaction: transaction, fee: transaction.fee)
        return try buildForSendRaw(txInputData: txInputData, signature: signature)
    }

    func buildForSignRaw(txInputData: Data) throws -> Data {
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: cosmosChain.coin, txInputData: txInputData)
        let output = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if output.error != .ok {
            throw BlockchainSdkError.failedToBuildTx
        }

        return output.dataHash
    }

    func buildForSendRaw(txInputData: Data, signature: Data) throws -> Data {
        let publicKeys = DataVector()
        publicKeys.add(data: publicKey)

        let signatures = DataVector()
        // We should delete last byte from signature
        signatures.add(data: signature.dropLast(1))

        let transactionData = TransactionCompiler.compileWithSignatures(
            coinType: cosmosChain.coin,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )

        let output = try CosmosSigningOutput(serializedData: transactionData)

        if output.error != .ok {
            throw BlockchainSdkError.failedToBuildTx
        }

        guard let outputData = output.serialized.data(using: .utf8) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return outputData
    }

    func serializeInput(
        gas: UInt64,
        feeAmount: String,
        feeDenomiation: String,
        messages: [WalletCore.TW_Cosmos_Proto_Message],
        memo: String?
    ) throws -> Data {
        guard let accountNumber, let sequenceNumber else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let fee = CosmosFee.with { fee in
            fee.gas = gas
            fee.amounts = [
                CosmosAmount.with { amount in
                    amount.amount = feeAmount
                    amount.denom = feeDenomiation
                },
            ]
        }

        let input = CosmosSigningInput.with {
            $0.mode = .sync
            $0.signingMode = .protobuf
            $0.accountNumber = accountNumber
            $0.chainID = cosmosChain.chainID
            $0.sequence = sequenceNumber
            $0.publicKey = publicKey
            $0.messages = messages
            $0.privateKey = Data(repeating: 1, count: 32)
            $0.fee = fee
            $0.memo = memo ?? ""
        }

        let serialized = try input.serializedData()
        return serialized
    }

    // MARK: Private

    private func makeInput(transaction: Transaction, fee: Fee?) throws -> Data {
        let decimalValue: Decimal
        switch transaction.amount.type {
        case .coin:
            decimalValue = cosmosChain.blockchain.decimalValue
        case .token:
            switch cosmosChain.blockchain.feePaidCurrency {
            case .coin:
                decimalValue = cosmosChain.blockchain.decimalValue
            case .sameCurrency:
                decimalValue = transaction.amount.type.token?.decimalValue ?? cosmosChain.blockchain.decimalValue
            case .token(let token):
                decimalValue = token.decimalValue
            case .feeResource:
                throw BlockchainSdkError.empty
            }
        case .reserve, .feeResource, .tokenYieldSupply:
            throw BlockchainSdkError.failedToBuildTx
        }

        let message: CosmosMessage
        if let token = transaction.amount.type.token, cosmosChain.allowCW20Tokens {
            guard let amountBytes = transaction.amount.encoded else {
                throw BlockchainSdkError.failedToBuildTx
            }

            let tokenMessage = CosmosMessage.WasmExecuteContractTransfer.with {
                $0.senderAddress = transaction.sourceAddress
                $0.recipientAddress = transaction.destinationAddress
                $0.contractAddress = token.contractAddress
                $0.amount = amountBytes
            }

            message = CosmosMessage.with {
                $0.wasmExecuteContractTransferMessage = tokenMessage
            }
        } else {
            let amountInSmallestDenomination = ((transaction.amount.value * decimalValue) as NSDecimalNumber).uint64Value
            let denomination = try denomination(for: transaction.amount)

            let sendCoinsMessage = CosmosMessage.Send.with {
                $0.fromAddress = transaction.sourceAddress
                $0.toAddress = transaction.destinationAddress
                $0.amounts = [CosmosAmount.with {
                    $0.amount = "\(amountInSmallestDenomination)"
                    $0.denom = denomination
                }]
            }
            message = CosmosMessage.with {
                $0.sendCoinsMessage = sendCoinsMessage
            }
        }

        guard let fee, let parameters = fee.parameters as? CosmosFeeParameters else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let feeAmountInSmallestDenomination = (fee.amount.value * decimalValue).uint64Value
        let feeDenomination = try feeDenomination(for: transaction.amount)
        let params = transaction.params as? CosmosTransactionParams

        let serializedInput = try serializeInput(
            gas: parameters.gas,
            feeAmount: "\(feeAmountInSmallestDenomination)",
            feeDenomiation: feeDenomination,
            messages: [message],
            memo: params?.memo
        )

        return serializedInput
    }

    private func denomination(for amount: Amount) throws -> String {
        switch amount.type {
        case .coin:
            return cosmosChain.smallestDenomination
        case .token(let token):
            guard let tokenDenomination = cosmosChain.tokenDenomination(contractAddress: token.contractAddress, tokenCurrencySymbol: token.symbol)
            else {
                throw BlockchainSdkError.failedToBuildTx
            }

            return tokenDenomination
        case .reserve, .feeResource, .tokenYieldSupply:
            throw BlockchainSdkError.failedToBuildTx
        }
    }

    private func feeDenomination(for amount: Amount) throws -> String {
        switch amount.type {
        case .coin:
            return cosmosChain.smallestDenomination
        case .token(let token):
            guard let tokenDenomination = cosmosChain.tokenFeeDenomination(contractAddress: token.contractAddress, tokenCurrencySymbol: token.symbol)
            else {
                throw BlockchainSdkError.failedToBuildTx
            }

            return tokenDenomination
        case .reserve, .feeResource, .tokenYieldSupply:
            throw BlockchainSdkError.failedToBuildTx
        }
    }
}

extension CosmosMessage {
    static func createStakeMessage(
        message: CosmosProtoMessage.CosmosMessageDelegate
    ) throws -> Self? {
        let type = message.messageType
        guard message.hasDelegateData else {
            return nil
        }
        let delegateData = message.delegateData

        switch type {
        case let string where string.contains(Constants.delegateMessage.rawValue):
            let delegateData = try CosmosProtoMessage.CosmosMessageDelegateContainer.DelegateData(
                serializedData: delegateData
            )
            let stakeMessage = CosmosMessage.Delegate.with { delegate in
                delegate.amount = CosmosAmount.with { amount in
                    amount.amount = delegateData.delegateAmount.amount
                    amount.denom = delegateData.delegateAmount.denomination
                }
                delegate.delegatorAddress = delegateData.delegatorAddress
                delegate.validatorAddress = delegateData.validatorAddress
            }
            return CosmosMessage.with {
                $0.stakeMessage = stakeMessage
            }
        case let string where string.contains(Constants.withdrawMessage.rawValue):
            let delegateData = try CosmosProtoMessage.CosmosMessageDelegateContainer.DelegateData(
                serializedData: delegateData
            )
            let withdrawMessage = CosmosMessage.WithdrawDelegationReward.with { reward in
                reward.delegatorAddress = delegateData.delegatorAddress
                reward.validatorAddress = delegateData.validatorAddress
            }
            return CosmosMessage.with {
                $0.withdrawStakeRewardMessage = withdrawMessage
            }
        case let string where string.contains(Constants.undelegateMessage.rawValue):
            let delegateData = try CosmosProtoMessage.CosmosMessageDelegateContainer.DelegateData(
                serializedData: delegateData
            )
            let delegateAmount = delegateData.delegateAmount
            let unstakeMessage = CosmosMessage.Undelegate.with { delegate in
                delegate.amount = CosmosAmount.with { amount in
                    amount.amount = delegateAmount.amount
                    amount.denom = delegateAmount.denomination
                }
                delegate.delegatorAddress = delegateData.delegatorAddress
                delegate.validatorAddress = delegateData.validatorAddress
            }
            return CosmosMessage.with {
                $0.unstakeMessage = unstakeMessage
            }
        case let string where string.contains(Constants.redelegate.rawValue):
            let redelegateData = try CosmosProtoMessage.CosmosMessageDelegateContainer.RedelegateData(
                serializedData: delegateData
            )
            let redelegateAmount = redelegateData.delegateAmount
            let restakeMessage = CosmosMessage.BeginRedelegate.with { redelegate in
                redelegate.amount = CosmosAmount.with { amount in
                    amount.amount = redelegateAmount.amount
                    amount.denom = redelegateAmount.denomination
                }
                redelegate.delegatorAddress = redelegateData.delegatorAddress
                redelegate.validatorDstAddress = redelegateData.validatorDstAddress
                redelegate.validatorSrcAddress = redelegateData.validatorSrcAddress
            }
            return CosmosMessage.with {
                $0.restakeMessage = restakeMessage
            }
        default: return nil
        }
    }
}

extension CosmosMessage {
    enum Constants: String {
        case delegateMessage = "MsgDelegate"
        case withdrawMessage = "MsgWithdrawDelegatorReward"
        case undelegateMessage = "MsgUndelegate"
        case redelegate = "MsgBeginRedelegate"
    }
}
