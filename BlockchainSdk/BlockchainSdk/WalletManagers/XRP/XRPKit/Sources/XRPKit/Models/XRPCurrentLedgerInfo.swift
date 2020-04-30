//
//  XRPCurrentLedgerInfo.swift
//  BigInt
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public struct XRPCurrentLedgerInfo {
    
    public init(index: Int, minFee: Int, maxFee: Int) {
        self.index = index
        self.minFee = minFee
        self.maxFee = maxFee
    }
    
    public var index: Int
    public var minFee: Int
    public var maxFee: Int
}
