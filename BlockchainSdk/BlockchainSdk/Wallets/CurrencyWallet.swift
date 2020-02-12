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
    public let config: WalletConfig
    public let exploreUrl: String? = nil
    public let shareUrl: String? = nil
    var pendingTransactions: [Transaction] = []
    var balances: [AmountType:Amount] = [:]
    public var address: String {
        return balances[.coin]!.address
    }
    
    init(address: String, blockchain: Blockchain, config: WalletConfig) {
        self.blockchain = blockchain
        self.config = config
        add(amount: Amount(with: blockchain, address: address))
    }
    
    func validateTransaction(amount: Amount, fee: Amount?) -> ValidationError? {
        guard let amountValue = amount.value, validate(amount: amount) else {
            return .wrongAmount
        }
        
        guard let fee = fee else {
            return nil
        }
        
        guard let feeValue = fee.value, validate(amount: fee) else {
            return .wrongFee
        }
        
        if amount.type == fee.type,
            !validate(amount: Amount(with: amount, value: amountValue + feeValue)) {
            return .wrongTotal
        }
        
        return nil
    }
    
    private func validate(amount: Amount) -> Bool {
        guard let amountValue = amount.value,
            amountValue > 0,
            let total = balances[amount.type]?.value, total >= amountValue else {
                return false
        }
        
        return true
    }
    
    func add(amount: Amount) {
        balances[amount.type] = amount
    }
    
    func add(transaction: Transaction) {
        var tx = transaction
        tx.date = Date()
        pendingTransactions.append(tx)
    }
}
