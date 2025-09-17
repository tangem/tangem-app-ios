//
//  BlockBookTarget.AddressRequestParameters.FilterType+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension BlockBookTarget.AddressRequestParameters.FilterType {
    init(amountType: Amount.AmountType) {
        switch amountType {
        case .coin, .reserve, .feeResource, .tokenYieldSupply:
            self = .coin
        case .token(let token):
            self = .contract(token.contractAddress)
        }
    }
}
