//
//  Amount.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Amount: CustomStringConvertible {
    public enum AmountType {
        case coin
        case token
        case reserve
    }
    
    public let type: AmountType
    public let currencySymbol: String
    public var value: Decimal
    public let decimals: Int
    
    public var description: String {
        return "\(value.rounded(decimals)) \(currencySymbol)"
    }
    
    public init(with blockchain: Blockchain, address: String, type: AmountType = .coin, value: Decimal) {
        self.type = type
        currencySymbol = blockchain.currencySymbol
        decimals = blockchain.decimalCount
        self.value = value
    }
    
    public init(with token: Token, value: Decimal) {
        type = .token
        currencySymbol = token.currencySymbol
        decimals = token.decimalCount
        self.value = value
    }
    
    public init(with amount: Amount, value: Decimal) {
        type = amount.type
        currencySymbol = amount.currencySymbol
        decimals = amount.decimals
        self.value = value
    }
}


