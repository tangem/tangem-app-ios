//
//  Decimal+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension Decimal {
    /// return 8 bytes of integer. LittleEndian  format
    var bytes8LE: [UInt8] {
        let int64value = (self as NSDecimalNumber).intValue
        let bytes8 =  int64value.bytes8
        return Array(bytes8)
    }
    
    init?(_ string: String?) {
        guard let string = string else {
            return nil
        }
        
        self.init(string: string)
    }
    
    init?(_ int: Int?) {
        guard let int = int else {
            return nil
        }
        
        self.init(int)
    }
    
    init?(data: Data) {
        guard let uint64 = UInt64(data: data) else {
            return nil
        }
        
        self.init(uint64)
    }
    
    mutating func round(_ scale: Int, _ roundingMode: NSDecimalNumber.RoundingMode = .plain) {
        var localCopy = self
        NSDecimalRound(&self, &localCopy, scale, roundingMode)
    }
    
    func rounded(_ scale: Int, _ roundingMode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, roundingMode)
        return result
    }
    
    public func rounded(blockchain: Blockchain) -> Decimal {
        return rounded(Int(blockchain.decimalCount), blockchain.roundingMode)
    }
}
