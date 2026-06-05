//
//  TokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee]
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee]
}

// MARK: - EthereumTokenFeeLoader

protocol EthereumTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee

    /// `approveInput` switches the estimate to the one-tap approve+swap mode: the swap gas is estimated
    /// with the allowance overridden to unlimited (the estimate would revert otherwise), the approve fee
    /// is estimated by the same loader — always in its own fee currency — and folded into every option's
    /// total (`nil` = normal estimate).
    func getFee(
        amount: BSDKAmount,
        destination: String,
        txData: Data,
        otherNativeFee: Decimal?,
        approveInput: ApproveWithSwapInput?
    ) async throws -> [BSDKFee]
}

// MARK: - SolanaTokenFeeLoader

protocol SolanaTokenFeeLoader: TokenFeeLoader {
    func getFee(compiledTransaction data: Data) async throws -> [BSDKFee]
}

// MARK: - TokenFeeLoader+

extension TokenFeeLoader {
    func asEthereumTokenFeeLoader() throws -> EthereumTokenFeeLoader {
        guard let ethereumTokenFeeLoader = self as? EthereumTokenFeeLoader else {
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }

        return ethereumTokenFeeLoader
    }

    func asSolanaTokenFeeLoader() throws -> SolanaTokenFeeLoader {
        guard let solanaTokenFeeLoader = self as? SolanaTokenFeeLoader else {
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }

        return solanaTokenFeeLoader
    }
}

enum TokenFeeLoaderError: LocalizedError {
    case tokenFeeLoaderNotFound
    case approveFeeNotFound
    case gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem
    case feeTokenIdNotFound
    case missingFeeRecipientAddress
    case gaslessExecutionReverted(gaslessMinTokenAmount: Decimal)
    case executionReverted

    var errorDescription: String? {
        switch self {
        case .tokenFeeLoaderNotFound: "TokenFeeLoader not found"
        case .approveFeeNotFound: "Approve fee not found"
        case .gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem: "GaslessEthereumTokenFeeLoader supports only token as fee token item"
        case .feeTokenIdNotFound: "Fee token id not found"
        case .missingFeeRecipientAddress: "Missing fee recipient address"
        case .gaslessExecutionReverted(let gaslessMinTokenAmount): "Gasless fee estimation execution reverted, min token amount: \(gaslessMinTokenAmount)"
        case .executionReverted: "Execution reverted"
        }
    }
}
