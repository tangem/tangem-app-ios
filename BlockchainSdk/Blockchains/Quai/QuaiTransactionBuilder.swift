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
    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)
        let unsignedProto = protoUtil.buildUnsignedProto(signingInput: input)
        let hashForSign = unsignedProto.sha3(.keccak256)
        return hashForSign
    }

    func buildForSend(transaction: Transaction, signatureInfo: SignatureInfo) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)
        let signature = try Secp256k1Signature(with: signatureInfo.signature)
        let unmarshalSignature = try signature.unmarshal(with: signatureInfo.publicKey, hash: Data())

        let vBytes = unmarshalSignature.v
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
