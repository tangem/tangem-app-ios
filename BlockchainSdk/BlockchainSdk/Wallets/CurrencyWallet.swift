//
//  CommonWallet.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

struct CurrencyWallet: Wallet, TransactionValidator {
    let blockchain: Blockchain
    let config: WalletConfig
    let exploreUrl: String? = nil
    let shareUrl: String? = nil
    var pendingTransactions: [Transaction] = []
    var balances: [AmountType:Amount] = [:]
    var address: String {
        return balances[.coin]!.address
    }
    
    init(address: String, blockchain: Blockchain, config: WalletConfig) {
        self.blockchain = blockchain
        self.config = config
        let coinAmount = Amount(type: .coin, currencySymbol: blockchain.currencySymbol, value: nil, address: address, decimals: blockchain.decimalCount)
        addAmount(coinAmount)
    }
    
    func validateTransaction(amount: Amount?, fee: Amount?) -> ValidationError? {
        return nil
    }
    
    mutating func addAmount(_ amount: Amount) {
        balances[amount.type] = amount
    }
}
