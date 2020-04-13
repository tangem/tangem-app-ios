//
//  CommonWallet.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public class CurrencyWallet: Wallet, TransactionValidator {
    public let blockchain: Blockchain
    public let address: String
    public let exploreUrl: String? = nil
    public let shareUrl: String? = nil
    public let token: Token?
    var pendingTransactions: [Transaction] = []
    var balances: [Amount.AmountType:Amount] = [:]
    
    public var allowLoad: Bool {
        return true
    }
    
    public var allowExtract: Bool {
        return true
    }
    
    init(address: String, blockchain: Blockchain, token: Token?)  {
        self.blockchain = blockchain
        self.address = address
        self.token = token
    }
    
    func validateTransaction(amount: Amount, fee: Amount?) -> ValidationError? {
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
    
    private func validate(amount: Amount) -> Bool {
        guard amount.value > 0,
            let total = balances[amount.type]?.value, total >= amount.value else {
                return false
        }
        
        return true
    }
    
    func add(amount: Amount) {
        balances[amount.type] = amount
    }
    
    func add(tokenValue: Decimal) {
        if let token = self.token {
            let amount = Amount(with: token, value: tokenValue)
            add(amount: amount)
        }
    }
    
    func add(coinValue: Decimal) {
        let amount = Amount(with: blockchain, address: address, type: .coin, value: coinValue)
        add(amount: amount)
    }
    
    func add(reserveValue: Decimal) {
        let amount = Amount(with: blockchain, address: address, type: .reserve, value: reserveValue)
        add(amount: amount)
    }
    
    func add(transaction: Transaction) {
        var tx = transaction
        tx.date = Date()
        pendingTransactions.append(tx)
    }
    
    func addIncomingTransaction() {
        let dummyAmount = Amount(with: blockchain, address: "unknown", type: .coin, value: 0)
        var tx = Transaction(amount: dummyAmount, fee: dummyAmount, sourceAddress: "unknown", destinationAddress: address)
        tx.date = Date()
        pendingTransactions.append(tx)
    }
    
    func createTransaction(amount: Amount, fee: Amount, destinationAddress: String) -> Result<Transaction,ValidationError> {
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
