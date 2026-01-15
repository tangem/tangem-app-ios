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
enum TokenFeeProviderInputData {
    case common(amount: Decimal, destination: String)

    case cex(amount: Decimal)
    case dex(_ type: TokenFeeProviderInputDataDEXType)
}

enum TokenFeeProviderInputDataDEXType {
    case ethereum(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?)
    case ethereumEstimate(estimatedGasLimit: Int, otherNativeFee: Decimal?)

    case solana(compiledTransaction: Data)
}
