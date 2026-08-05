//
//  BSDKFee+Gasless.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

extension BSDKFee {
    var isGasless: Bool {
        if parameters is TronGaslessFeeParameters {
            return true
        }

        guard let ethereumFeeParameters = parameters as? EthereumFeeParameters else {
            return false
        }

        if case .gasless = ethereumFeeParameters.parametersType {
            return true
        }

        return false
    }
}
