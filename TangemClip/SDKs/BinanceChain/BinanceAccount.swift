//
//  BinanceAccount.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class BinanceAccount: CustomStringConvertible {
    public var accountNumber: Int = 0
    public var address: String = ""
    public var balances: [BinanceBalance] = []
    public var publicKey: Data = Data()
    public var sequence: Int = 0
    
    var description: String {
        "Binance account info with number: \(accountNumber), with address: \(address), balance: \(balances), pubkey: \(publicKey.asHexString()), sequence: \(sequence)"
    }
}

class BinanceBalance: CustomStringConvertible {
    public var symbol: String = ""
    public var free: Double = 0
    public var locked: Double = 0
    public var frozen: Double = 0
    
    var description: String {
        "Binance balance for currency with symbol: \(symbol). Free: \(free), Locked: \(locked), Frozen: \(frozen)"
    }
}
