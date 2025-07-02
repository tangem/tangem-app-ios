//
//  TokenItem+ExpressCurrency.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

extension TokenItem {
    var expressCurrency: ExpressWalletCurrency {
        switch self {
        case .blockchain:
            return ExpressWalletCurrency(
                // Fixed constant value for the main token contract address
                contractAddress: ExpressConstants.coinContractAddress,
                network: networkId,
                decimalCount: decimalCount
            )
        case .token(let token, _):
            return ExpressWalletCurrency(
                contractAddress: token.contractAddress,
                network: networkId,
                decimalCount: decimalCount
            )
        }
    }
}
