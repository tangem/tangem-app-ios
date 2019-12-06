//
//  Wallet.swift
//  blockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public protocol Wallet {
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
    var type: AmountType = .coin
    var currencySymbol: String = ""
    var value: Decimal = 0
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
    func validateTransaction(amount: Amount?, fee: Amount?) -> ValidationError?
}
