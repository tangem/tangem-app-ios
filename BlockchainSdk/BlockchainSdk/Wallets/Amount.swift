//
//  Amount.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Amount {
    public enum AmountType {
        case coin
        case token
        case reserve
    }
    
    let type: AmountType
    let currencySymbol: String
    var value: Decimal? //[REDACTED_TODO_COMMENT]
    let address: String
    let decimals: Int
    
    public init(with blockchain: Blockchain, address: String, type: AmountType = .coin, value: Decimal? = nil) {
        self.type = type
        currencySymbol = blockchain.currencySymbol
        decimals = blockchain.decimalCount
        self.value = value
        self.address = address
    }
    
    public init(with token: Token, value: Decimal? = nil) {
        type = .token
        currencySymbol = token.currencySymbol
        decimals = token.decimalCount
        self.value = value
        self.address = token.contractAddress
    }
    
    public init(with amount: Amount, value: Decimal? = nil) {
        type = amount.type
        currencySymbol = amount.currencySymbol
        decimals = amount.decimals
        self.value = value
        address = amount.address
    }
}


