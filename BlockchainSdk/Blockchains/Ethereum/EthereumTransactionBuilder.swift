//
//  EthereumTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemSdk
import WalletCore

// MARK: - EthereumTransactionBuilder

protocol EthereumTransactionBuilder {
    func buildForSign(transaction: Transaction) throws -> Data
    func buildForSend(transaction: Transaction, signatureInfo: SignatureInfo) throws -> Data
    func buildDummyTransactionForL1(destination: String, value: String?, data: Data?, fee: Fee) throws -> Data
    func buildTxCompilerPreSigningOutput(input: EthereumSigningInput) throws -> TxCompilerPreSigningOutput
    func buildSigningOutput(input: EthereumSigningInput, signatureInfo: SignatureInfo) throws -> EthereumSigningOutput
    func buildSigningInput(destination: String, coinAmount: BigUInt, fee: Fee, nonce: Int, data: Data?) throws -> EthereumSigningInput
    func buildSigningInput(transaction: Transaction) throws -> EthereumSigningInput
    func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data
    func buildForApprove(spender: String, amount: Decimal) -> Data
    func buildTransactionDataFor(transaction: Transaction) throws -> Data
}

enum EthereumTransactionBuilderError: LocalizedError, Equatable {
    case feeParametersNotFound
    case transactionParamsNotFound
    case invalidSignatureCount
    case invalidAmount
    case invalidNonce
    case transactionEncodingFailed
    case walletCoreError(message: String)
    case invalidStakingTransaction
    case unsupportedContractType
    case missingChainId
    case transactionHasParams

    var errorDescription: String? {
        switch self {
        case .feeParametersNotFound:
            return "feeParametersNotFound"
        case .transactionParamsNotFound:
            return "transactionParamsNotFound"
        case .invalidAmount:
            return "invalidAmount"
        case .invalidNonce:
            return "invalidNonce"
        case .invalidSignatureCount:
            return "invalidSignatureCount"
        case .transactionEncodingFailed:
            return "transactionEncodingFailed"
        case .walletCoreError(let message):
            return "walletCoreError: \(message)"
        case .invalidStakingTransaction:
            return "invalidStakingTransaction"
        case .unsupportedContractType:
            return "unsupportedContractType"
        case .missingChainId:
            return "missingChainId"
        case .transactionHasParams:
            return "transactionHasParams"
        }
    }
}
