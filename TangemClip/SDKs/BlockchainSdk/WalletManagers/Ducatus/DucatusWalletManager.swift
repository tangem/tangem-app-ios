//
//  DucatusWalletManager.swift
//  Alamofire
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

class DucatusWalletManager: BitcoinWalletManager {
    override func updateWallet(with response: [BitcoinResponse]) {
        let singleResponse = response.first!
        wallet.add(coinValue: singleResponse.balance)
        if singleResponse.hasUnconfirmed {
            if wallet.transactions.isEmpty {
                wallet.addPendingTransaction()
            }
        } else {
            for index in wallet.transactions.indices {
                if let txDate = wallet.transactions[index].date {
                    let interval = Date().timeIntervalSince(txDate)
                    if interval > 30 {
                        wallet.transactions[index].status = .confirmed
                    }
                }
            }
        }
    }
}
