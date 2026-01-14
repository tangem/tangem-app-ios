//
//  CommonEthereumTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemSdk
import WalletCore

// MARK: - CommonEthereumTransactionBuilder

// Decoder: https://rawtxdecode.in
class CommonEthereumTransactionBuilder: EthereumTransactionBuilder {
    private let chainId: Int
    private let coinType: CoinType
    private let sourceAddress: Address

    init(
        chainId: Int,
        sourceAddress: Address
    ) {
        self.chainId = chainId
        self.sourceAddress = sourceAddress
        coinType = .ethereum
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)
        let preSigningOutput = try buildTxCompilerPreSigningOutput(input: input)
        return preSigningOutput.dataHash
    }

    func buildForSend(transaction: Transaction, signatureInfo: SignatureInfo) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)
        let output = try buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }

    func buildDummyTransactionForL1(destination: String, value: String?, data: Data?, fee: Fee) throws -> Data {
        let amountValue = BigUInt(Data(hex: value ?? "0x0"))

        switch fee.amount.type {
        case .coin:
            let input = try buildSigningInput(
                destination: destination,
                coinAmount: amountValue,
                fee: fee,
                // The nonce for the dummy transaction won't be used later, so we can just mock it with any value
                nonce: 1,
                data: data
            )
            return try buildTxCompilerPreSigningOutput(input: input).data

        case .token(let token):
            let method = try makeTokenTransferSmartContractMethod(
                destination: destination,
                amount: amountValue,
                token: token
            )
            let data = method.data
            let input = try buildSigningInput(
                destination: token.contractAddress,
                coinAmount: .zero,
                fee: fee,
                // The nonce for the dummy transaction won't be used later, so we can just mock it with any value
                nonce: 1,
                data: data
            )

            return try buildTxCompilerPreSigningOutput(input: input).data

        case .reserve, .feeResource:
            throw BlockchainSdkError.notImplemented
        }
    }

    // MARK: - Transaction data builder

    func buildForApprove(spender: String, amount: Decimal) -> Data {
        let bigUInt = EthereumUtils.mapToBigUInt(amount)
        return ApproveERC20TokenMethod(spender: spender, amount: bigUInt).data
    }

    func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data {
        guard case .token(let token) = amount.type else {
            return Data()
        }

        guard let amountValue = amount.bigUIntValue else {
            throw EthereumTransactionBuilderError.invalidAmount
        }

        let method = try makeTokenTransferSmartContractMethod(
            destination: destination,
            amount: amountValue,
            token: token
        )

        return method.data
    }

    func buildSigningInput(destination: String, coinAmount: BigUInt, fee: Fee, nonce: Int, data: Data?) throws -> EthereumSigningInput {
        guard nonce >= 0 else {
            throw EthereumTransactionBuilderError.invalidNonce
        }

        guard let feeParameters = fee.parameters as? EthereumFeeParameters else {
            throw EthereumTransactionBuilderError.feeParametersNotFound
        }

        let input = EthereumSigningInput.with { input in
            input.chainID = BigUInt(chainId).serialize()
            input.nonce = BigUInt(nonce).serialize()
            input.toAddress = destination

            input.transaction = .with { transaction in
                transaction.contractGeneric = .with {
                    $0.amount = coinAmount.serialize()
                    if let data {
                        $0.data = data
                    }
                }
            }

            switch feeParameters.parametersType {
            case .eip1559(let eip1559Parameters):
                // EIP-1559. https://eips.ethereum.org/EIPS/eip-1559
                input.txMode = .enveloped
                input.gasLimit = eip1559Parameters.gasLimit.serialize()
                input.maxFeePerGas = eip1559Parameters.maxFeePerGas.serialize()
                input.maxInclusionFeePerGas = eip1559Parameters.priorityFee.serialize()
            case .legacy(let legacyParameters):
                input.txMode = .legacy
                input.gasLimit = legacyParameters.gasLimit.serialize()
                input.gasPrice = legacyParameters.gasPrice.serialize()
            case .gasless(let gaslessParameters):
                input.txMode = .enveloped
                input.gasLimit = gaslessParameters.gasLimit.serialize()
                input.maxFeePerGas = gaslessParameters.maxFeePerGas.serialize()
                input.maxInclusionFeePerGas = gaslessParameters.priorityFee.serialize()
            }
        }

        return input
    }

    func buildTxCompilerPreSigningOutput(input: EthereumSigningInput) throws -> TxCompilerPreSigningOutput {
        let txInputData = try input.serializedData()
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if preSigningOutput.error != .ok {
            BSDKLogger.error("EthereumPreSigningOutput has a error", error: preSigningOutput.errorMessage)
            throw EthereumTransactionBuilderError.walletCoreError(message: preSigningOutput.errorMessage)
        }

        return preSigningOutput
    }

    func buildSigningOutput(input: EthereumSigningInput, signatureInfo: SignatureInfo) throws -> EthereumSigningOutput {
        guard signatureInfo.signature.count == Constants.signatureSize else {
            throw EthereumTransactionBuilderError.invalidSignatureCount
        }

        let decompressed = try Secp256k1Key(with: signatureInfo.publicKey).decompress()
        let secp256k1Signature = try Secp256k1Signature(with: signatureInfo.signature)
        let unmarshal = try secp256k1Signature.unmarshal(with: decompressed, hash: signatureInfo.hash)
        let txInputData = try input.serializedData()

        // As we use the chainID in the transaction according to EIP-155
        // WalletCore will use formula to calculate `V`.
        // v = CHAIN_ID * 2 + 35
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md

        let encodedV = EthereumCalculateSignatureUtil().encodeSignatureVBytes(value: unmarshal.v)
        let signature = unmarshal.r + unmarshal.s + encodedV

        let signatures = DataVector()
        signatures.add(data: signature)

        let publicKeys = DataVector()
        publicKeys.add(data: decompressed)

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )

        let output = try EthereumSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
            BSDKLogger.error("EthereumSigningOutput has a error", error: output.errorMessage)
            throw EthereumTransactionBuilderError.walletCoreError(message: output.errorMessage)
        }

        if output.encoded.isEmpty {
            throw EthereumTransactionBuilderError.transactionEncodingFailed
        }

        return output
    }

    func buildTransactionPayload(transaction: Transaction) throws -> TransactionPayload {
        guard let amountValue = transaction.amount.bigUIntValue else {
            throw EthereumTransactionBuilderError.failedToBuildTxPayload
        }

        let signingInput = try buildSigningInput(transaction: transaction)

        // Duplicates part of the amount resolution logic from `buildSigningInput`,
        // as the native coin amount is not exposed by `EthereumSigningInput`
        let amount: BigUInt = switch transaction.amount.type {
        case .coin:
            amountValue
        case .token:
            .zero
        case .reserve, .feeResource:
            throw EthereumTransactionBuilderError.failedToBuildTxPayload
        }

        return TransactionPayload(
            destinationAddress: signingInput.toAddress,
            data: signingInput.transaction.contractGeneric.data,
            coinAmount: amount
        )
    }

    func buildSigningInput(transaction: Transaction) throws -> EthereumSigningInput {
        guard let amountValue = transaction.amount.bigUIntValue else {
            throw EthereumTransactionBuilderError.invalidAmount
        }

        guard let parameters = transaction.params as? EthereumTransactionParams else {
            throw EthereumTransactionBuilderError.transactionParamsNotFound
        }

        guard let nonce = parameters.nonce else {
            throw EthereumTransactionBuilderError.invalidNonce
        }

        switch transaction.amount.type {
        case .coin:
            return try buildSigningInput(
                destination: transaction.destinationAddress,
                coinAmount: amountValue,
                fee: transaction.fee,
                nonce: nonce,
                data: parameters.data
            )

        case .token(let token):
            let contract = if let yieldSupply = token.metadata.yieldSupply {
                yieldSupply.yieldContractAddress
            } else {
                transaction.contractAddress ?? token.contractAddress
            }
            let method = try makeTokenTransferSmartContractMethod(
                destination: transaction.destinationAddress,
                amount: amountValue,
                token: token
            )
            let data = parameters.data ?? method.data

            return try buildSigningInput(
                destination: contract,
                coinAmount: .zero,
                fee: transaction.fee,
                nonce: nonce,
                data: data
            )

        case .reserve, .feeResource:
            throw BlockchainSdkError.notImplemented
        }
    }
}

private extension CommonEthereumTransactionBuilder {
    func makeTokenTransferSmartContractMethod(
        destination: String,
        amount: BigUInt,
        token: Token
    ) throws -> SmartContractMethod {
        switch token.metadata.kind {
        case .fungible where token.metadata.yieldSupply != nil:
            return YieldSendMethod(
                tokenContractAddress: token.contractAddress,
                destination: destination,
                amount: amount
            )

        case .fungible:
            return TransferERC20TokenMethod(destination: destination, amount: amount)

        case .nonFungible(let assetIdentifier, .erc721):
            let source = sourceAddress.value
            return try TransferERC721TokenMethod(
                source: source,
                destination: destination,
                assetIdentifier: assetIdentifier
            )

        case .nonFungible(let assetIdentifier, .erc1155):
            let source = sourceAddress.value
            return try TransferERC1155TokenMethod(
                source: source,
                destination: destination,
                assetIdentifier: assetIdentifier,
                assetAmount: amount
            )

        case .nonFungible(_, .unspecified):
            // Currently only ERC721 and ERC1155 contract types are supported,
            // so receiving an `.unspecified` contract type here is a programming error
            throw EthereumTransactionBuilderError.unsupportedContractType
        }
    }
}

private extension CommonEthereumTransactionBuilder {
    enum Constants {
        static let signatureSize = 64
    }
}
