//
//  QuaiTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BigInt
import TangemSdk

final class QuaiTransactionBuilder {
    // MARK: - Private Proprties

    private let ethereumTransactionBuilder: EthereumTransactionBuilder
    private let protoUtil = QuaiProtobufUtils()

    // MARK: - Init

    init(chainId: Int, sourceAddress: any Address) {
        ethereumTransactionBuilder = CommonEthereumTransactionBuilder(chainId: chainId, sourceAddress: sourceAddress)
    }
}

// MARK: - EthereumTransactionBuilder

extension QuaiTransactionBuilder: EthereumTransactionBuilder {
    func buildTransactionDataFor(transaction: Transaction) throws -> Data {
        try ethereumTransactionBuilder.buildTransactionDataFor(transaction: transaction)
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)
        let buildForSign = try convertToHashSigning(input: input)
        return buildForSign
    }

    func buildForSend(transaction: Transaction, signatureInfo: SignatureInfo) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)

        let decompressed = try Secp256k1Key(with: signatureInfo.publicKey).decompress()
        let secp256k1Signature = try Secp256k1Signature(with: signatureInfo.signature)
        let unmarshalSignature = try secp256k1Signature.unmarshal(with: decompressed, hash: signatureInfo.hash)

        let vBytes = EthereumCalculateSignatureUtil().encodeSignatureVBytes(value: unmarshalSignature.v)
        let rBytes = unmarshalSignature.r
        let sBytes = unmarshalSignature.s

        let buildForSend = protoUtil.convertSigningInputToProtobuf(
            signingInput: input,
            vSignature: vBytes,
            rSignature32: rBytes,
            sSignature32: sBytes
        )

        return buildForSend
    }

    func buildDummyTransactionForL1(destination: String, value: String?, data: Data?, fee: Fee) throws -> Data {
        try ethereumTransactionBuilder.buildDummyTransactionForL1(destination: destination, value: value, data: data, fee: fee)
    }

    func buildTxCompilerPreSigningOutput(input: EthereumSigningInput) throws -> TxCompilerPreSigningOutput {
        try ethereumTransactionBuilder.buildTxCompilerPreSigningOutput(input: input)
    }

    func buildSigningOutput(input: EthereumSigningInput, signatureInfo: SignatureInfo) throws -> EthereumSigningOutput {
        try ethereumTransactionBuilder.buildSigningOutput(input: input, signatureInfo: signatureInfo)
    }

    func buildSigningInput(destination: String, coinAmount: BigUInt, fee: Fee, nonce: Int, data: Data?) throws -> EthereumSigningInput {
        try ethereumTransactionBuilder.buildSigningInput(destination: destination, coinAmount: coinAmount, fee: fee, nonce: nonce, data: data)
    }

    func buildSigningInput(transaction: Transaction) throws -> EthereumSigningInput {
        try ethereumTransactionBuilder.buildSigningInput(transaction: transaction)
    }

    func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data {
        try ethereumTransactionBuilder.buildForTokenTransfer(destination: destination, amount: amount)
    }

    func buildForApprove(spender: String, amount: Decimal) -> Data {
        ethereumTransactionBuilder.buildForApprove(spender: spender, amount: amount)
    }
}

private extension QuaiTransactionBuilder {
    private func convertToHashSigning(input: EthereumSigningInput) throws -> Data {
        let unsignedProto = protoUtil.buildUnsignedProto(signingInput: input)
        let hashForSign = unsignedProto.sha3(.keccak256)
        return hashForSign
    }
}
