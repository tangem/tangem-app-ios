//
//  GaslessTransactionDataBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt
import struct TangemSdk.Secp256k1Key
import struct TangemSdk.Secp256k1Signature

extension GaslessTransactionDataBuilder {
    struct GaslessTransactionsEIP712Util {
        let domainName = "Tangem7702GaslessExecutor"
        let domainVersion = "1"
        let primaryType = "GaslessTransaction"

        // MARK: - Public Implementation

        func makeGaslessTypedData(
            transaction: GaslessTransactionData.Transaction,
            fee: GaslessTransactionData.Fee,
            nonce: String,
            chainId: String,
            verifyingContract: String
        ) -> EIP712TypedData {
            let types: [String: [EIP712Type]] = [
                "EIP712Domain": [
                    .init(name: "name", type: "string"),
                    .init(name: "version", type: "string"),
                    .init(name: "chainId", type: "uint256"),
                    .init(name: "verifyingContract", type: "address"),
                ],
                "Transaction": [
                    .init(name: "to", type: "address"),
                    .init(name: "value", type: "uint256"),
                    .init(name: "data", type: "bytes"),
                ],
                "Fee": [
                    .init(name: "feeToken", type: "address"),
                    .init(name: "maxTokenFee", type: "uint256"),
                    .init(name: "coinPriceInToken", type: "uint256"),
                    .init(name: "feeTransferGasLimit", type: "uint256"),
                    .init(name: "baseGas", type: "uint256"),
                ],
                primaryType: [
                    .init(name: "transaction", type: "Transaction"),
                    .init(name: "fee", type: "Fee"),
                    .init(name: "nonce", type: "uint256"),
                ],
            ]

            let domain: JSON = .object([
                "name": .string(domainName),
                "version": .string(domainVersion),
                "chainId": .string(chainId),
                "verifyingContract": .string(verifyingContract),
            ])

            let message: JSON = .object([
                "transaction": .object([
                    "to": .string(transaction.address),
                    "value": .string(transaction.value),
                    "data": .string(transaction.data.hexString.addHexPrefix()),
                ]),
                "fee": .object([
                    "feeToken": .string(fee.feeToken),
                    "maxTokenFee": .string(fee.maxTokenFee),
                    "coinPriceInToken": .string(fee.coinPriceInToken),
                    "feeTransferGasLimit": .string(fee.feeTransferGasLimit),
                    "baseGas": .string(fee.baseGas),
                ]),
                "nonce": .string(nonce),
            ])

            return EIP712TypedData(types: types, primaryType: primaryType, domain: domain, message: message)
        }
    }
}

enum UnmarshalUtilError: Error {
    case incorrectSignatureLength
    case failedToExtractYParity
}

enum UnmarshalUtil {
    struct UnmarshalledSignature {
        let r: Data
        let s: Data
        let yParity: Int
    }

    static func unmarshalSignature(signatureInfo: SignatureInfo, publicKey: Data) throws -> UnmarshalledSignature {
        guard signatureInfo.signature.count == 64 else {
            throw UnmarshalUtilError.incorrectSignatureLength
        }

        let decompressedPublicKey = try Secp256k1Key(with: publicKey).decompress()
        let signature = try Secp256k1Signature(with: signatureInfo.signature)
        let unmarshaled = try signature.unmarshal(with: decompressedPublicKey, hash: signatureInfo.hash)

        guard let yParity = EthereumCalculateSignatureUtil().extractYParity(from: unmarshaled.v) else {
            throw UnmarshalUtilError.failedToExtractYParity
        }

        return UnmarshalledSignature(r: unmarshaled.r, s: unmarshaled.s, yParity: yParity)
    }
}

extension GaslessTransactionDataBuilder {
    enum GaslessTransactionData {
        struct GaslessTransaction {
            let transaction: Transaction
            let fee: Fee
            let nonce: String
            let signedData: SignedGaslessData
        }

        struct Transaction {
            let address: String
            let value: String
            let data: Data
        }

        struct Fee {
            let feeToken: String
            let maxTokenFee: String
            let coinPriceInToken: String
            let feeTransferGasLimit: String
            let baseGas: String
        }

        struct SignedGaslessData {
            let eip712Signature: String
            let eip7702Auth: String
        }
    }
}

//// 7) Create updated fee params and compute fee amount
// let newParams = EthereumEIP1559FeeParameters(gasLimit: newGasLimit, maxFeePerGas: doubledMaxFeePerGas, priorityFee: params.priorityFee)
// let fee = newParams.calculateFee(decimalValue: wallet.blockchain.decimalValue)
//
//// 8) Return Fee with updated params and computed amount
// return Fee(.init(with: wallet.blockchain, value: fee), parameters: newParams)

enum MetaTransactionBuilderError: Error {
    case failedToBuildMetaTransaction
    case failedToMakeGaslessTransactionFee
}

struct GaslessTransactionDataBuilder {
    let walletModel: any WalletModel
    let signer: TangemSigner
    let balanceConverter = BalanceConverter()

    func buildMetaTransaction(bsdkTransaction: BSDKTransaction, tokenFee: TokenFee) async throws {
        guard let chainId = tokenFee.tokenItem.blockchain.chainId else {
            throw MetaTransactionBuilderError.failedToBuildMetaTransaction
        }

        // 1) get transaction data
        guard let ethParams = bsdkTransaction.params as? EthereumTransactionParams,
              let callData = ethParams.data
        else {
            throw MetaTransactionBuilderError.failedToBuildMetaTransaction
        }

        let transaction = GaslessTransactionData.Transaction(
            address: bsdkTransaction.destinationAddress,
            value: "0",
            data: callData
        )

        // 3) get gasless contract nonce

        let nonce = try await getSmartContractNonce()

        // 4) get fee data

        let feeData = try await makeGaslessTransactionFee(tokenFee: tokenFee)

        // 5) get unmarshalled eip7702 data

        let eip7702Data = try await getEIP7702Data()

        let eip7702SignatureResult = try await signer
            .sign(hash: eip7702Data.data, walletPublicKey: walletModel.publicKey)
            .mapToResult()
            .async()

        guard case .success(let signatureInfo) = eip7702SignatureResult else {
            throw MetaTransactionBuilderError.failedToBuildMetaTransaction
        }

        let unmarshalledEIP7702Sig = try UnmarshalUtil.unmarshalSignature(
            signatureInfo: signatureInfo,
            publicKey: walletModel.publicKey.blockchainKey,
        )

        // 6) Get EIP712 data

        let smartContractNonce = try await getSmartContractNonce()

        let eip712Hash = try await makeEIP712Hash(
            transaction: transaction,
            fee: feeData,
            nonce: smartContractNonce.description,
            chainId: chainId.description
        )

        let eip712SignatureResult = try await signer
            .sign(hash: eip712Hash, walletPublicKey: walletModel.publicKey)
            .mapToResult()
            .async()

        guard case .success(let eip712SignatureInfo) = eip712SignatureResult else {
            throw MetaTransactionBuilderError.failedToBuildMetaTransaction
        }

        let unmarshalledEIP712Sig = try UnmarshalUtil.unmarshalSignature(
            signatureInfo: eip712SignatureInfo,
            publicKey: walletModel.publicKey.blockchainKey,
        )
    }

    // MARK: - Private Implementation

    private func makeEIP712Hash(
        transaction: GaslessTransactionData.Transaction,
        fee: GaslessTransactionData.Fee,
        nonce: String,
        chainId: String
    ) async throws -> Data {
        guard let provider = walletModel.ethereumGaslessDataProvider else {
            throw MetaTransactionBuilderError.failedToBuildMetaTransaction
        }

        let verifyingContract = try provider.getGaslessExecutorContractAddress()

        let typedData = GaslessTransactionsEIP712Util().makeGaslessTypedData(
            transaction: transaction,
            fee: fee,
            nonce: nonce,
            chainId: chainId,
            verifyingContract: verifyingContract
        )

        return typedData.signHash
    }

    private func makeGaslessTransactionFee(tokenFee: TokenFee) async throws -> GaslessTransactionData.Fee {
        guard case .success(let bsdkFee) = tokenFee.value,
              let parameters = bsdkFee.parameters as? EthereumEIP1559FeeParameters,
              let tokenId = tokenFee.tokenItem.id,
              let contractAddress = tokenFee.tokenItem.contractAddress
        else {
            throw MetaTransactionBuilderError.failedToBuildMetaTransaction
        }

        let feeTransferGasLimit = parameters.gasLimit
        let feeInCoin = bsdkFee.amount.value
        let coinPriceInToken = try await calculateCoinPriceInToken(tokenId: tokenId)
        let maxTokenFee = coinPriceInToken * feeInCoin

        return GaslessTransactionData.Fee(
            feeToken: contractAddress,
            maxTokenFee: maxTokenFee.stringValue,
            coinPriceInToken: coinPriceInToken.stringValue,
            feeTransferGasLimit: feeTransferGasLimit.description,
            baseGas: Constants.baseGas
        )
    }

    private func calculateCoinPriceInToken(tokenId: String) async throws -> Decimal {
        let coinId = walletModel.tokenItem.blockchain.coinId

        let coinInFiat = try await balanceConverter.convertToFiat(1, currencyId: coinId)
        let tokenInFiat = try await balanceConverter.convertToFiat(1, currencyId: tokenId)

        var coinPriceInToken = coinInFiat / tokenInFiat

        // Shift the decimal point to the right by token decimals
        coinPriceInToken *= walletModel.tokenItem.blockchain.decimalValue

        // Add 1% on top (client-side only, backend skips this step)
        coinPriceInToken *= Decimal(1.01)

        // 6. Keep only the integer part, rounding up
        let rounded = coinPriceInToken.rounded(roundingMode: .up)
        return rounded
    }

    private func getEIP7702Data() async throws -> EIP7702AuthorizationData {
        guard let provider = walletModel.ethereumGaslessDataProvider else {
            throw MetaTransactionBuilderError.failedToBuildMetaTransaction
        }

        return try await provider.prepareEIP7702AuthorizationData()
    }

    private func getSmartContractNonce() async throws -> BigUInt {
        guard let networkProvider = walletModel.ethereumNetworkProvider else {
            throw MetaTransactionBuilderError.failedToBuildMetaTransaction
        }

        return try await networkProvider.getSmartContractNonce()
    }
}

// MARK: - Constants

extension GaslessTransactionDataBuilder {
    enum Constants {
        static let baseGas = "100000"
    }
}
