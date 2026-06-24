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

    func asBitcoinTokenFeeLoader() throws -> BitcoinTokenFeeLoader {
        guard let bitcoinTokenFeeLoader = self as? BitcoinTokenFeeLoader else {
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }

        return bitcoinTokenFeeLoader
    }
}

enum TokenFeeLoaderError: LocalizedError {
    case tokenFeeLoaderNotFound
    case approveFeeNotFound
    case swapFeeParametersNotFound
    case gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem
    case feeTokenIdNotFound
    case missingFeeRecipientAddress
    case gaslessExecutionReverted(gaslessMinTokenAmount: Decimal)
    case executionReverted

    var errorDescription: String? {
        switch self {
        case .tokenFeeLoaderNotFound: "TokenFeeLoader not found"
        case .approveFeeNotFound: "Approve fee not found"
        case .swapFeeParametersNotFound: "Swap fee parameters are not EthereumFeeParameters"
        case .gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem: "GaslessEthereumTokenFeeLoader supports only token as fee token item"
        case .feeTokenIdNotFound: "Fee token id not found"
        case .missingFeeRecipientAddress: "Missing fee recipient address"
        case .gaslessExecutionReverted(let gaslessMinTokenAmount): "Gasless fee estimation execution reverted, min token amount: \(gaslessMinTokenAmount)"
        case .executionReverted: "Execution reverted"
        }
    }
}
