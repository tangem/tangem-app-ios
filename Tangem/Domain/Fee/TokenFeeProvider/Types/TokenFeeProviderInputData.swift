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

    case cexEstimate(amount: Decimal)

    case dexEthereumEstimate(estimatedGasLimit: Int, otherNativeFee: Decimal?)
    case dexEthereum(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?)
    case dexSolana(compiledTransaction: Data)
}
