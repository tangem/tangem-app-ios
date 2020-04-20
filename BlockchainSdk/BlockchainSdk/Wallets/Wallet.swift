//
//  Wallet.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public struct Wallet {
    public let blockchain: Blockchain
    public let address: String
    public let exploreUrl: URL
    public let shareString: String
    public let token: Token?
    public var transactions: [Transaction] = []
    public var amounts: [Amount.AmountType:Amount] = [:]
    
    internal init(blockchain: Blockchain, address: String, token: Token? = nil) {
        self.blockchain = blockchain
        self.address = address
        self.exploreUrl = blockchain.getExploreURL(from: address, token: token)
        self.shareString = blockchain.getShareString(from: address)
        self.token = token
    }

    
    func validateTransaction(amount: Amount, fee: Amount?) -> ValidationError? { //[REDACTED_TODO_COMMENT]
        guard validate(amount: amount) else {
            return .wrongAmount
        }
        
        guard let fee = fee else {
            return nil
        }
        
        guard validate(amount: fee) else {
            return .wrongFee
        }
        
        if amount.type == fee.type,
            !validate(amount: Amount(with: amount, value: amount.value + fee.value)) {
            return .wrongTotal
        }
        
        return nil
    }
    
    private func validate(amount: Amount) -> Bool { //[REDACTED_TODO_COMMENT]
        guard amount.value > 0,
            let total = amounts[amount.type]?.value, total >= amount.value else {
                return false
        }
        
        return true
    }
    
    mutating func add(amount: Amount) {
        amounts[amount.type] = amount
    }
    
    mutating func add(tokenValue: Decimal) {
        if let token = self.token {
            let amount = Amount(with: token, value: tokenValue)
            add(amount: amount)
        }
    }
    
    mutating func add(coinValue: Decimal) {
        let amount = Amount(with: blockchain, address: address, type: .coin, value: coinValue)
        add(amount: amount)
    }
    
    mutating func add(reserveValue: Decimal) {
        let amount = Amount(with: blockchain, address: address, type: .reserve, value: reserveValue)
        add(amount: amount)
    }
    
    mutating func add(transaction: Transaction) {
        var tx = transaction
        tx.date = Date()
        transactions.append(tx)
    }
    
    mutating func addIncomingTransaction() {
        let dummyAmount = Amount(with: blockchain, address: "unknown", type: .coin, value: 0)
        var tx = Transaction(amount: dummyAmount, fee: dummyAmount, sourceAddress: "unknown", destinationAddress: address)
        tx.date = Date()
        transactions.append(tx)
    }
    
    func createTransaction(amount: Amount, fee: Amount, destinationAddress: String) -> Result<Transaction,ValidationError> { //[REDACTED_TODO_COMMENT]
        let transaction = Transaction(amount: amount,
                                      fee: fee,
                                      sourceAddress: address,
                                      destinationAddress: destinationAddress,
                                      contractAddress: token?.contractAddress,
                                      date: Date(),
                                      status: .unconfirmed,
                                      hash: nil)

        if let error = validateTransaction(amount: amount, fee: fee)  {
            return .failure(error)
        } else {
            return .success(transaction)
        }
    }
}
