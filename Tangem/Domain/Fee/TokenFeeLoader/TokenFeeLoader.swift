//
//  TokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee]
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee]

    /// Whether the loader must reject swap inputs whose bridge fee is paid in the blockchain coin because it can't forward coin value.
    /// true for gasless loaders
    var rejectsBridgeCoinFee: Bool { get }
    /// Whether a triple fee for revoke-and-approve is available only when `usdtRevokeGaslessFee` is enabled.
    /// tru for EVM gasless
    var tripleApproveFeeRequiresFeature: Bool { get }

    func supports(_ input: TokenFeeProviderInputData) -> Bool
    func loadFees(_ input: TokenFeeProviderInputData, feeBlockchain: Blockchain) async throws -> [BSDKFee]
}

// MARK: - EthereumTokenFeeLoader

struct EthereumFeeRequestData {
    let amount: BSDKAmount
    let destination: String
    let txData: Data
    let otherNativeFee: Decimal?
}

protocol EthereumTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee
    func getFee(request: EthereumFeeRequestData) async throws -> [BSDKFee]
    func getApproveWithSwapFee(
        request: EthereumFeeRequestData,
        approveInput: ApproveWithSwapInput
    ) async throws -> [BSDKFee]
}

// MARK: - SolanaTokenFeeLoader

protocol SolanaTokenFeeLoader: TokenFeeLoader {
    func getFee(compiledTransaction data: Data) async throws -> [BSDKFee]
}

// MARK: - BitcoinTokenFeeLoader

protocol BitcoinTokenFeeLoader: TokenFeeLoader {
    func getFee(psbtBase64: String) async throws -> [BSDKFee]
}

// MARK: - TronTokenFeeLoader

struct TronFeeRequestData: Hashable {
    let amount: BSDKAmount
    let destination: String
    /// Non-nil prices a smart-contract call (`amount` must be coin-typed — its value becomes the
    /// TRX `call_value`); `nil` prices a plain transfer of `amount`.
    let callData: Data?
    /// Affects the fee: flat memo fee + extra bandwidth.
    let memo: String?
    let otherNativeFee: Decimal?
}

protocol TronTokenFeeLoader: TokenFeeLoader {
    func getFee(request: TronFeeRequestData) async throws -> [BSDKFee]
}

// MARK: - Defaults

extension TokenFeeLoader {
    var rejectsBridgeCoinFee: Bool { false }
    var tripleApproveFeeRequiresFeature: Bool { false }
}

enum TokenFeeLoaderError: LocalizedError {
    case tokenFeeLoaderNotFound
    case approveFeeNotFound
    case swapFeeParametersNotFound
    case gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem
    case gaslessTronTokenFeeSupportOnlyTokenTransactions
    case gaslessTronTransactionAmountConversionFailed(Decimal)
    case invalidGaslessTronCompensationAmount(String)
    case feeTokenIdNotFound
    case missingFeeRecipientAddress
    case notEnoughFeeBalance
    case noLatestImplementationForUpgrade
    case yieldModuleVersionUnsupported
    case gaslessExecutionReverted(gaslessMinTokenAmount: Decimal)
    case executionReverted

    var errorDescription: String? {
        switch self {
        case .tokenFeeLoaderNotFound: "TokenFeeLoader not found"
        case .approveFeeNotFound: "Approve fee not found"
        case .swapFeeParametersNotFound: "Swap fee parameters are not EthereumFeeParameters"
        case .gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem: "GaslessEthereumTokenFeeLoader supports only token as fee token item"
        case .gaslessTronTokenFeeSupportOnlyTokenTransactions: "GaslessTronTokenFeeLoader supports only token transactions"
        case .gaslessTronTransactionAmountConversionFailed(let amount): "Failed to convert Tron gasless transaction amount to raw value: \(amount)"
        case .invalidGaslessTronCompensationAmount(let amount): "Invalid compensation amount in Tron gasless quote: \(amount)"
        case .feeTokenIdNotFound: "Fee token id not found"
        case .missingFeeRecipientAddress: "Missing fee recipient address"
        case .notEnoughFeeBalance: "Not enough fee balance"
        case .noLatestImplementationForUpgrade: "No latest implementation for upgrade"
        case .yieldModuleVersionUnsupported: "Yield module version does not support yield-paid fee"
        case .gaslessExecutionReverted(let gaslessMinTokenAmount): "Gasless fee estimation execution reverted, min token amount: \(gaslessMinTokenAmount)"
        case .executionReverted: "Execution reverted"
        }
    }
}
