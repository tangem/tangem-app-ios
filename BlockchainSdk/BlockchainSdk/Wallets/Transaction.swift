//
//  Transaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Transaction {
    public let amount: Amount
    public let fee: Amount
    public let sourceAddress: String
    public let destinationAddress: String
    public let contractAddress: String?
    public internal(set) var date: Date? = nil
    public internal(set) var status: TransactionStatus = .unconfirmed
    public internal(set) var hash: String? = nil
    
    internal init(amount: Amount, fee: Amount, sourceAddress: String, destinationAddress: String, contractAddress: String? = nil, date: Date? = nil, status: TransactionStatus = .unconfirmed, hash: String? = nil) {
        self.amount = amount
        self.fee = fee
        self.sourceAddress = sourceAddress
        self.destinationAddress = destinationAddress
        self.contractAddress = contractAddress
        self.date = date
        self.status = status
        self.hash = hash
    }
}

public enum TransactionStatus {
    case unconfirmed
    case confirmed
}

struct ValidationError: OptionSet, Error {
    let rawValue: Int
    static let wrongAmount = ValidationError(rawValue: 0 << 1)
    static let wrongFee = ValidationError(rawValue: 0 << 2)
    static let wrongTotal = ValidationError(rawValue: 0 << 3)
}

protocol TransactionValidator {
    func validateTransaction(amount: Amount, fee: Amount?) -> ValidationError?
}
