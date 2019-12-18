//
//  Wallet.swift
//  blockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public protocol Wallet {
    var blockchain: Blockchain {get}
    var config: WalletConfig {get}
    var address: String {get}
    var exploreUrl: String? {get}
    var shareUrl: String? {get}
}

public struct WalletConfig {
    public let allowFeeSelection: Bool
    public let allowFeeInclusion: Bool
    public var allowExtract: Bool = false
    public var allowLoad: Bool = false
}

public struct Amount {
    let type: AmountType
    let currencySymbol: String
    let value: Decimal?
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

public struct Transaction {
    let amount: Amount
    let fee: Amount?
    let sourceAddress: String
    let destinationAddress: String
}

public enum AmountType {
    case coin
    case token
    case reserve
}

struct ValidationError: OptionSet {
    let rawValue: Int
    static let wrongAmount = ValidationError(rawValue: 0 << 1)
    static let wrongFee = ValidationError(rawValue: 0 << 2)
    static let wrongTotal = ValidationError(rawValue: 0 << 3)
}

protocol TransactionValidator {
    func validateTransaction(amount: Amount, fee: Amount?) -> ValidationError?
}
