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
import TangemFoundation

struct GaslessTransactionBuilder {
    typealias GaslessTransaction = GaslessTransactionsDTO.Request.GaslessTransaction
    typealias GaslessBatchTransaction = GaslessTransactionsDTO.Request.GaslessBatchTransaction
    typealias TransactionData = GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData
    typealias BatchTransactionData = GaslessTransactionsDTO.Request.GaslessBatchTransaction.TransactionData
    typealias GaslessTransactionFee = TransactionData.Fee
    typealias EIP7702Auth = GaslessTransactionsDTO.Request.GaslessTransaction.EIP7702Auth

    let walletModel: any WalletModel
    let signer: TangemSigner
    let balanceConverter = BalanceConverter()

    // MARK: - Public Implementation

    func buildGaslessTransactionRequest(bsdkTransaction: BSDKTransaction, feeRecipientAddress: String) async throws -> GaslessTransactionBuildResult {
        guard let chainId = walletModel.tokenItem.blockchain.chainId else {
            throw GaslessTransactionBuilderError.missingChainId
        }

        let (parameters, _) = try gaslessFeeParameters(from: bsdkTransaction.fee)

        if let yieldWithdraw = parameters.yieldWithdraw {
            return try await buildGaslessBatchTransaction(
                bsdkTransaction: bsdkTransaction,
                feeRecipientAddress: feeRecipientAddress,
                chainId: chainId,
                yieldWithdraw: yieldWithdraw
            )
        }

        let transaction = try await makeTransaction(from: bsdkTransaction, gasLimit: nil)
        let smartContractNonce = try await getSmartContractNonce(address: walletModel.defaultAddressString)

        let feeData = try await makeGaslessTransactionFee(bsdkFee: bsdkTransaction.fee, feeRecipientAddress: feeRecipientAddress)
        let transactionData = TransactionData(transaction: transaction, fee: feeData, nonce: smartContractNonce)

        let signedData = try await makeSignedGaslessData(
            transaction: transaction,
            fee: feeData,
            chainId: chainId,
            smartContractNonce: smartContractNonce,
            feeRecipientAddress: feeRecipientAddress
        )

        let gaslessTransaction = GaslessTransaction(
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

        return .single(gaslessTransaction)
    }

    private func buildGaslessBatchTransaction(
        bsdkTransaction: BSDKTransaction,
        feeRecipientAddress: String,
        chainId: Int,
        yieldWithdraw: EthereumGaslessTransactionFeeParameters.YieldWithdraw
    ) async throws -> GaslessTransactionBuildResult {
        let transaction = try await makeTransaction(
            from: bsdkTransaction,
            gasLimit: yieldWithdraw.originalGasLimit.description
        )
        let (yieldTransaction, yieldTransactionHandlesUpgrade) = try makeUpgradeWrappedYieldTransactionIfNeeded(
            transaction,
            yieldWithdraw: yieldWithdraw
        )
        let smartContractNonce = try await getSmartContractNonce(address: walletModel.defaultAddressString)

        let feeData = try await makeGaslessTransactionFee(bsdkFee: bsdkTransaction.fee, feeRecipientAddress: feeRecipientAddress)
        let withdrawTransaction = try makeYieldWithdrawTransaction(
            bsdkFee: bsdkTransaction.fee,
            fee: feeData,
            yieldWithdraw: yieldWithdraw,
            shouldWrapUpgrade: !yieldTransactionHandlesUpgrade
        )

        let transactions = [yieldTransaction, withdrawTransaction]
        let transactionData = BatchTransactionData(transactions: transactions, fee: feeData, nonce: smartContractNonce)

        let signedData = try await makeSignedGaslessBatchData(
            transactions: transactions,
            fee: feeData,
            chainId: chainId,
            smartContractNonce: smartContractNonce,
            feeRecipientAddress: feeRecipientAddress
        )

        let batchTransaction = GaslessBatchTransaction(
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

        return .batch(batchTransaction)
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
        feeRecipientAddress: String
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

    private func makeSignedGaslessBatchData(
        transactions: [TransactionData.Transaction],
        fee: GaslessTransactionFee,
        chainId: Int,
        smartContractNonce: String,
        feeRecipientAddress: String
    ) async throws -> SignedData {
        let eip7702Data = try await getEIP7702Data()

        let eip712Hash = try await makeBatchEIP712Hash(
            transactions: transactions,
            fee: fee,
            nonce: smartContractNonce,
            chainId: chainId
        )

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

    private func makeTransaction(from bsdkTransaction: BSDKTransaction, gasLimit: String?) async throws -> TransactionData.Transaction {
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
            gasLimit: gasLimit,
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
            verifyingContract: walletModel.defaultAddressString,
        )

        return typedData.signHash
    }

    private func makeBatchEIP712Hash(
        transactions: [TransactionData.Transaction],
        fee: GaslessTransactionFee,
        nonce: String,
        chainId: Int
    ) async throws -> Data {
        let typedData = GaslessTransactionsEIP712Util().makeGaslessBatchTypedData(
            transactions: transactions,
            fee: fee,
            nonce: nonce,
            chainId: chainId,
            verifyingContract: walletModel.defaultAddressString,
        )

        return typedData.signHash
    }

    private func makeGaslessTransactionFee(bsdkFee: BSDKFee, feeRecipientAddress: String) async throws -> GaslessTransactionFee {
        let (parameters, token) = try gaslessFeeParameters(from: bsdkFee)
        guard parameters.gasLimit > 0 else {
            throw GaslessTransactionBuilderError.invalidFeeParameters
        }

        let maxTokenFeeInTokenUnitsDecimal = (bsdkFee.amount.value * token.decimalValue)
            .rounded(roundingMode: .up)

        guard let maxTokenFeeInTokenUnits = BigUInt(decimal: maxTokenFeeInTokenUnitsDecimal) else {
            throw GaslessTransactionBuilderError.invalidFeeParameters
        }

        let bufferedCoinPriceInTokenUnits = (
            parameters.bufferedNativeToFeeTokenRate.rounded(scale: token.decimalCount) * token.decimalValue
        ).description

        let feeTransferGasLimit = parameters.feeTokenTransferGasLimit.description
        let baseGas = EthereumFeeParametersConstants.gaslessBaseGasBuffer.description

        return GaslessTransactionFee(
            feeToken: token.contractAddress,
            maxTokenFee: maxTokenFeeInTokenUnits.description,
            coinPriceInToken: bufferedCoinPriceInTokenUnits,
            feeTransferGasLimit: feeTransferGasLimit,
            baseGas: baseGas,
            feeReceiver: feeRecipientAddress
        )
    }

    private func makeYieldWithdrawTransaction(
        bsdkFee: BSDKFee,
        fee: GaslessTransactionFee,
        yieldWithdraw: EthereumGaslessTransactionFeeParameters.YieldWithdraw,
        shouldWrapUpgrade: Bool
    ) throws -> TransactionData.Transaction {
        let (_, token) = try gaslessFeeParameters(from: bsdkFee)

        guard let maxTokenFee = BigUInt(fee.maxTokenFee) else {
            throw GaslessTransactionBuilderError.invalidFeeParameters
        }

        let withdrawMethod = WithdrawMethod(tokenContractAddress: token.contractAddress, amount: maxTokenFee)
        let withdrawData: Data

        switch (yieldWithdraw.upgrade, shouldWrapUpgrade) {
        case (.required(let upgradeImplementation), true):
            withdrawData = UpgradeToAndCallMethod(
                newImplementation: upgradeImplementation,
                callData: withdrawMethod.data
            ).data
        default:
            withdrawData = withdrawMethod.data
        }

        return TransactionData.Transaction(
            to: yieldWithdraw.yieldContractAddress,
            value: "0",
            gasLimit: yieldWithdraw.withdrawGasLimit.description,
            data: withdrawData.hexString.addHexPrefix()
        )
    }

    private func makeUpgradeWrappedYieldTransactionIfNeeded(
        _ transaction: TransactionData.Transaction,
        yieldWithdraw: EthereumGaslessTransactionFeeParameters.YieldWithdraw
    ) throws -> (transaction: TransactionData.Transaction, handlesUpgrade: Bool) {
        guard case .required(let upgradeImplementation) = yieldWithdraw.upgrade else {
            return (transaction, false)
        }

        guard transaction.to.caseInsensitiveEquals(to: yieldWithdraw.yieldContractAddress) else {
            return (transaction, false)
        }

        guard !UpgradeToAndCallMethod.isEncodedCall(transaction.data) else {
            return (transaction, true)
        }

        let method = UpgradeToAndCallMethod(
            newImplementation: upgradeImplementation,
            callData: Data(hexString: transaction.data)
        )

        return (
            TransactionData.Transaction(
                to: transaction.to,
                value: transaction.value,
                gasLimit: transaction.gasLimit,
                data: method.encodedData
            ),
            true
        )
    }

    private func gaslessFeeParameters(from bsdkFee: BSDKFee) throws -> (EthereumGaslessTransactionFeeParameters, Token) {
        guard let parameters = bsdkFee.parameters as? EthereumGaslessTransactionFeeParameters else {
            throw GaslessTransactionBuilderError.invalidFeeParameters
        }
        guard case .token(let token) = bsdkFee.amount.type else {
            throw GaslessTransactionBuilderError.unsupportedFeeToken
        }

        return (parameters, token)
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

// MARK: - Approve & swap flow

extension GaslessTransactionBuilder {
    func buildGaslessTransactions(bsdkTransactions: [BSDKTransaction], feeRecipientAddress: String) async throws -> [GaslessTransaction] {
        guard let chainId = walletModel.tokenItem.blockchain.chainId else {
            throw GaslessTransactionBuilderError.missingChainId
        }

        guard let networkProvider = walletModel.ethereumNetworkProvider else {
            throw GaslessTransactionBuilderError.missingNetworkProvider
        }

        let baseNonce = try await networkProvider.getSmartContractNonce(for: walletModel.defaultAddressString).async()
        let eip7702Data = try await getEIP7702Data()

        var transactionsData: [TransactionData] = []
        var eip712Hashes: [Data] = []

        for (index, bsdkTransaction) in bsdkTransactions.enumerated() {
            let transaction = try await makeTransaction(from: bsdkTransaction, gasLimit: nil)
            let feeData = try await makeGaslessTransactionFee(bsdkFee: bsdkTransaction.fee, feeRecipientAddress: feeRecipientAddress)
            let nonce = (baseNonce + index).description

            transactionsData.append(TransactionData(transaction: transaction, fee: feeData, nonce: nonce))
            eip712Hashes.append(try await makeEIP712Hash(transaction: transaction, fee: feeData, nonce: nonce, chainId: chainId))
        }

        let signedHashes = try await signer
            .sign(hashes: [eip7702Data.data] + eip712Hashes, walletPublicKey: walletModel.publicKey)
            .async()

        guard signedHashes.count == eip712Hashes.count + 1 else {
            throw GaslessTransactionBuilderError.invalidSignaturesCount
        }

        let eip7702Unmarshalled = try UnmarshalUtil.unmarshalSignature(
            signatureInfo: signedHashes[0],
            publicKey: walletModel.publicKey.blockchainKey
        )

        let eip7702Auth = EIP7702Auth(
            chainId: eip7702Data.chainId,
            address: eip7702Data.address,
            nonce: eip7702Data.nonce.description,
            yParity: eip7702Unmarshalled.yParity,
            r: eip7702Unmarshalled.r.hexString.addHexPrefix(),
            s: eip7702Unmarshalled.s.hexString.addHexPrefix()
        )

        return try transactionsData.enumerated().map { index, transactionData in
            let eip712Unmarshalled = try UnmarshalUtil.unmarshalSignature(
                signatureInfo: signedHashes[index + 1],
                publicKey: walletModel.publicKey.blockchainKey
            )

            return GaslessTransaction(
                gaslessTransaction: transactionData,
                signature: eip712Unmarshalled.extended.data.hexString.addHexPrefix(),
                userAddress: walletModel.defaultAddressString,
                chainId: chainId,
                eip7702auth: eip7702Auth
            )
        }
    }
}

extension GaslessTransactionBuilder {
    enum GaslessTransactionBuildResult {
        case single(GaslessTransaction)
        case batch(GaslessBatchTransaction)
    }

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
