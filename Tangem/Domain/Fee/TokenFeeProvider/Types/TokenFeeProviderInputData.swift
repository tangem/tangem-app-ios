//
//  TokenFeeProviderInputData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

@RawCaseName
enum TokenFeeProviderInputData: Hashable {
    case common(amount: Decimal, destination: String)

    case cex(amount: Decimal)
    case dex(_ type: TokenFeeProviderInputDataDEXType)
    /// Fee multiplier applied after estimation (e.g. 3x for revoke+approve flows).
    case approve(txData: Data, toContractAddress: String, feeMultiplier: FeeMultiplier = .single)
    /// One-tap approve+swap: the swap is estimated with an unlimited-allowance state override
    /// (the estimate would revert while the allowance is missing); the approve fee is estimated
    /// by the same loader — always in its own fee currency — and folded into every option's total.
    case approveWithSwap(
        amount: BSDKAmount,
        destination: String,
        txData: Data,
        otherNativeFee: Decimal?,
        approve: ApproveWithSwapInput
    )
}

struct ApproveWithSwapInput: Hashable {
    let txData: Data
    /// Approve tx destination == the token contract being approved.
    let tokenContractAddress: String
    let owner: String
    let spender: String
}

enum FeeMultiplier: Decimal, Hashable {
    /// Standard single-approve flow (1x fee).
    case single = 1
    /// Revoke-then-approve flow (3x fee: 1x revoke + 2x approve).
    case triple = 3
}

enum TokenFeeProviderInputDataDEXType: Hashable {
    case ethereum(
        amount: BSDKAmount,
        destination: String,
        txData: Data,
        otherNativeFee: Decimal?
    )

    case ethereumEstimate(estimatedGasLimit: Int, otherNativeFee: Decimal?)
    case solana(compiledTransaction: Data)
}
