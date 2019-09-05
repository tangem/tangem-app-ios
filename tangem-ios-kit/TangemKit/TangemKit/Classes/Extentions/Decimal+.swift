//
//  Decimal+.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

extension Decimal {
    var bytes8: [UInt8] {
        let int64value = (self as NSDecimalNumber).intValue
        let bytes8 =  int64value.bytes8
        return Array(bytes8)
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
    
    
    var btcToSatoshi: Decimal  {
        return self * Decimal(100000000)
    }
    
    var satoshiToBtc: Decimal {
        return self / Decimal(100000000)
    }
}
