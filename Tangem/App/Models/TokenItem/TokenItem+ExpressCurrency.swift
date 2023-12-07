//
//  TokenItem+ExpressCurrency.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

extension TokenItem {
    var expressCurrency: TangemSwapping.ExpressCurrency {
        switch self {
        case .blockchain(let blockchain):
            return TangemSwapping.ExpressCurrency(
                // Fixed constant value for the main token contract address
                contractAddress: ExpressConstants.coinContractAddress,
                network: blockchain.networkId
            )
        case .token(let token, let blockchain):
            return TangemSwapping.ExpressCurrency(
                contractAddress: token.contractAddress,
                network: blockchain.networkId
            )
        }
    }
}
