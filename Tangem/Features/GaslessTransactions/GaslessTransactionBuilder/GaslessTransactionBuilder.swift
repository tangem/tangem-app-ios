//
//  GaslessTransactionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt

struct GaslessTransactionBuilder {
    typealias GaslessTransaction = GaslessTransactionsDTO.Request.GaslessTransaction
    typealias TransactionData = GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData
    typealias GaslessTransactionFee = TransactionData.Fee
    typealias EIP7702Auth = GaslessTransactionsDTO.Request.GaslessTransaction.EIP7702Auth

    let walletModel: any WalletModel
    let signer: TangemSigner
    let balanceConverter = BalanceConverter()

    // MARK: - Public Implementation

    func builGaslessTransaction(bsdkTransaction: BSDKTransaction) async throws -> GaslessTransaction {
        guard let chainId = walletModel.tokenItem.blockchain.chainId else {
            throw GaslessTransactionBuilderError.missingChainId
        }

        let transaction = try await makeTransaction(from: bsdkTransaction)
        let smartContractNonce = try await getSmartContractNonce(address: walletModel.defaultAddressString)

        let feeData = try await makeGaslessTransactionFee(bsdkFee: bsdkTransaction.fee)
        let transactionData = TransactionData(transaction: transaction, fee: feeData, nonce: smartContractNonce)

        let signedData = try await makeSignedGaslessData(
            transaction: transaction,
            fee: feeData,
            chainId: chainId,
            smartContractNonce: smartContractNonce
        )

        return GaslessTransaction(
            gaslessTransaction: transactionData,
            signature: signedData.eip712Signature,
            userAddress: walletModel.defaultAddressString,
            chainId: chainId,
            eip7702auth: .init(
                chainId: signedData.eip7702Auth.chainId,
                address: signedData.eip7702Auth.address,
                nonce: signedData.eip7702Auth.nonce,
                yParity: signedData.eip7702Auth.yParity,
                r: signedData.eip7702Auth.r,
                s: signedData.eip7702Auth.s
            )
        )
    }

    // MARK: - Private Implementation

    /// Builds and signs gasless transaction data.
    /// Generates EIP-7702 auth data and EIP-712 hash, signs both payloads,
    /// unmarshals the signatures, and returns structured signatures
    /// required for a gasless meta-transaction.
    private func makeSignedGaslessData(
        transaction: TransactionData.Transaction,
        fee: GaslessTransactionFee,
        chainId: Int,
        smartContractNonce: String,
    ) async throws -> SignedData {
        let eip7702Data = try await getEIP7702Data()

        let eip712Hash = try await makeEIP712Hash(
            transaction: transaction,
            fee: fee,
            nonce: smartContractNonce,
            chainId: chainId
        )

        // Both eip7702Data.data and eip712Hash are 32-byte digests to be signed
        let signedHashes = try await signer
            .sign(hashes: [eip7702Data.data, eip712Hash], walletPublicKey: walletModel.publicKey)
            .async()

        let eip7702Unmarshalled = try UnmarshalUtil.unmarshalSignature(
            signatureInfo: signedHashes[0],
            publicKey: walletModel.publicKey.blockchainKey
        )

        let eip712Unmarshalled = try UnmarshalUtil.unmarshalSignature(
            signatureInfo: signedHashes[1],
            publicKey: walletModel.publicKey.blockchainKey
        )

        return SignedData(
            eip712Signature: eip712Unmarshalled.extended.data.hexString.addHexPrefix(),
            eip7702Auth: SignedData.EIP7702Auth(
                chainId: eip7702Data.chainId,
                address: eip7702Data.address,
                nonce: eip7702Data.nonce.description,
                yParity: eip7702Unmarshalled.yParity,
                r: eip7702Unmarshalled.r.hexString.addHexPrefix(),
                s: eip7702Unmarshalled.s.hexString.addHexPrefix()
            )
        )
    }

    private func makeTransaction(from bsdkTransaction: BSDKTransaction) async throws -> TransactionData.Transaction {
        guard let builder = walletModel.ethereumTransactionDataBuilder else {
            throw GaslessTransactionBuilderError.missingEthereumTransactionBuilder
        }

        let payload = try await builder.buildTransactionPayload(transaction: bsdkTransaction)

        guard payload.coinAmount.isZero else {
            throw GaslessTransactionBuilderError.transactionValueIsNotZero
        }

        return TransactionData.Transaction(
            to: payload.destinationAddress,
            value: payload.coinAmount.description,
            data: payload.data.hexString.addHexPrefix()
        )
    }

    private func makeEIP712Hash(
        transaction: TransactionData.Transaction,
        fee: GaslessTransactionFee,
        nonce: String,
        chainId: Int
    ) async throws -> Data {
        let typedData = GaslessTransactionsEIP712Util().makeGaslessTypedData(
            transaction: transaction,
            fee: fee,
            nonce: nonce,
            chainId: chainId,
            verifyingContract: walletModel.defaultAddress.value
        )

        return typedData.signHash
    }

    private func makeGaslessTransactionFee(bsdkFee: BSDKFee) async throws -> GaslessTransactionFee {
        guard let parameters = bsdkFee.parameters as? EthereumGaslessTransactionFeeParameters else {
            throw GaslessTransactionBuilderError.invalidFeeParameters
        }
        guard case .token(let token) = bsdkFee.amount.type else {
            throw GaslessTransactionBuilderError.unsupportedFeeToken
        }
        guard parameters.gasLimit > 0 else {
            throw GaslessTransactionBuilderError.invalidFeeParameters
        }

        let maxTokenFeeInTokenUnits = (bsdkFee.amount.value * token.decimalValue).intValue(roundingMode: .up).description
        var coinPriceInTokenUnits = (parameters.nativeToFeeTokenRate * token.decimalValue)

        coinPriceInTokenUnits *= 1.01

        return GaslessTransactionFee(
            feeToken: token.contractAddress,
            maxTokenFee: maxTokenFeeInTokenUnits,
            coinPriceInToken: coinPriceInTokenUnits.intValue(roundingMode: .up).description,
            feeTransferGasLimit: parameters.feeTokenTransferGasLimit.description,
            baseGas: Constants.baseGas
        )
    }

    private func getEIP7702Data() async throws -> EIP7702AuthorizationData {
        guard let provider = walletModel.ethereumGaslessDataProvider else {
            throw GaslessTransactionBuilderError.missingGaslessDataProvider
        }

        return try await provider.prepareEIP7702AuthorizationData()
    }

    private func getSmartContractNonce(address: String) async throws -> String {
        guard let networkProvider = walletModel.ethereumNetworkProvider else {
            throw GaslessTransactionBuilderError.missingNetworkProvider
        }

        return try await networkProvider.getSmartContractNonce(for: address).async().description
    }
}

// MARK: - Constants

extension GaslessTransactionBuilder {
    enum Constants {
        static let baseGas = "100000"
    }
}

extension GaslessTransactionBuilder {
    struct SignedData {
        let eip712Signature: String
        let eip7702Auth: EIP7702Auth

        struct EIP7702Auth {
            let chainId: Int
            let address: String
            let nonce: String
            let yParity: Int
            let r: String
            let s: String
        }
    }
}

extension GaslessTransactionBuilder {
    enum GaslessTransactionBuilderError: Error {
        // General
        case missingChainId
        case missingEthereumTransactionBuilder
        case missingGaslessDataProvider
        case missingNetworkProvider

        // Building data
        case failedToBuildTransactionData
        case failedToPrepareTypedData

        // Fee related
        case invalidFeeParameters
        case unsupportedFeeToken
        case missingTokenId
        case invalidPricing

        // Signing
        case failedToSignTransactions
        case invalidSignaturesCount

        /// Value
        case transactionValueIsNotZero
    }
}
