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
    typealias MetaTransaction = GaslessTransactionsDTO.Request.MetaTransaction
    typealias TransactionData = GaslessTransactionsDTO.Request.MetaTransaction.TransactionData
    typealias MetaTransactionFee = TransactionData.Fee
    typealias EIP7702Auth = GaslessTransactionsDTO.Request.MetaTransaction.EIP7702Auth

    let walletModel: any WalletModel
    let signer: TangemSigner
    let balanceConverter = BalanceConverter()

    // MARK: - Public Implementation

    func buildMetaTransaction(bsdkTransaction: BSDKTransaction) async throws -> MetaTransaction {
        guard let chainId = walletModel.tokenItem.blockchain.chainId else {
            throw GaslessTransactionBuilderError.missingChainId
        }

        let bigChainId = BigUInt(chainId)
        let transaction = try await makeTransaction(from: bsdkTransaction)
        let smartContractNonce = try await getSmartContractNonce()

        let feeData = try await makeGaslessTransactionFee(bsdkFee: bsdkTransaction.fee)
        let transactionData = TransactionData(transaction: transaction, fee: feeData, nonce: smartContractNonce)
        let signedData = try await makeSignedGaslessData(
            transaction: transaction,
            fee: feeData,
            chainId: chainId,
            smartContractNonce: smartContractNonce
        )

        return MetaTransaction(
            transactionData: transactionData,
            signature: signedData.eip712Signature,
            userAddress: walletModel.defaultAddressString,
            chainId: bigChainId,
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
        fee: MetaTransactionFee,
        chainId: Int,
        smartContractNonce: String,
    ) async throws -> SignedData {
        let eip7702Data = try await getEIP7702Data()

        let eip712Hash = try await makeEIP712Hash(
            transaction: transaction,
            fee: fee,
            nonce: smartContractNonce,
            chainId: chainId.description
        )

        // Both eip7702Data.data and eip712Hash are 32-byte digests to be signed
        let signedHashes = try await signer
            .sign(hashes: [eip7702Data.data, eip712Hash], walletPublicKey: walletModel.publicKey)
            .async()

        guard signedHashes.count == 2 else {
            throw GaslessTransactionBuilderError.invalidSignaturesCount
        }

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
            eip7702Auth: SignedData.EIP7702Authorization(
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

        let data = try await builder.buildTransactionDataFor(transaction: bsdkTransaction)

        return TransactionData.Transaction(
            address: bsdkTransaction.destinationAddress,
            value: "0",
            data: data.hexString.addHexPrefix()
        )
    }

    private func makeEIP712Hash(
        transaction: TransactionData.Transaction,
        fee: MetaTransactionFee,
        nonce: String,
        chainId: String
    ) async throws -> Data {
        guard let provider = walletModel.ethereumGaslessDataProvider else {
            throw GaslessTransactionBuilderError.missingGaslessDataProvider
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

    private func makeGaslessTransactionFee(bsdkFee: BSDKFee) async throws -> MetaTransactionFee {
        guard let parameters = bsdkFee.parameters as? EthereumEIP1559FeeParameters else {
            throw GaslessTransactionBuilderError.invalidFeeParameters
        }
        guard case .token(let token) = bsdkFee.amount.type else {
            throw GaslessTransactionBuilderError.unsupportedFeeToken
        }
        guard let tokenId = token.id else {
            throw GaslessTransactionBuilderError.missingTokenId
        }

        guard parameters.gasLimit > 0 else {
            throw GaslessTransactionBuilderError.invalidFeeParameters
        }

        let contractAddress = token.contractAddress
        let feeTransferGasLimit = parameters.gasLimit
        let feeInCoin = bsdkFee.amount.value
        let coinPriceInToken = try await calculateCoinPriceInToken(tokenId: tokenId)
        let maxTokenFee = coinPriceInToken * feeInCoin

        return MetaTransactionFee(
            feeToken: contractAddress,
            maxTokenFee: maxTokenFee.stringValue,
            coinPriceInToken: coinPriceInToken.stringValue,
            feeTransferGasLimit: feeTransferGasLimit.description,
            baseGas: Constants.baseGas
        )
    }

    /// Returns the coin price in token base units (integer) with 1% buffer and rounded up.
    private func calculateCoinPriceInToken(tokenId: String) async throws -> Decimal {
        let coinId = walletModel.tokenItem.blockchain.coinId

        let coinInFiat = try await balanceConverter.convertToFiat(1, currencyId: coinId)
        let tokenInFiat = try await balanceConverter.convertToFiat(1, currencyId: tokenId)

        guard coinInFiat > 0, tokenInFiat > 0 else {
            throw GaslessTransactionBuilderError.invalidPricing
        }

        var coinPriceInToken = coinInFiat / tokenInFiat

        // Shift the decimal point to the right by token decimals
        coinPriceInToken *= walletModel.tokenItem.blockchain.decimalValue

        // Add 1% on top
        coinPriceInToken *= Decimal(1.01)

        // Keep only the integer part, rounding up
        let rounded = coinPriceInToken.rounded(roundingMode: .up)
        return rounded
    }

    private func getEIP7702Data() async throws -> EIP7702AuthorizationData {
        guard let provider = walletModel.ethereumGaslessDataProvider else {
            throw GaslessTransactionBuilderError.missingGaslessDataProvider
        }

        return try await provider.prepareEIP7702AuthorizationData()
    }

    private func getSmartContractNonce() async throws -> String {
        guard let networkProvider = walletModel.ethereumNetworkProvider else {
            throw GaslessTransactionBuilderError.missingNetworkProvider
        }

        return try await networkProvider.getSmartContractNonce().description
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
        let eip7702Auth: EIP7702Authorization

        struct EIP7702Authorization {
            let chainId: BigUInt
            let address: String
            let nonce: String
            let yParity: BigUInt
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
    }
}
