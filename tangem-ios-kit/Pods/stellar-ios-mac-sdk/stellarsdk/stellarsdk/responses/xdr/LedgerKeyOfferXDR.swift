//
//  LedgerKeyOfferXDR.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct LedgerKeyOfferXDR: XDRCodable {
    let sellerId: PublicKey
    let offerId: UInt64
    
    init(sellerId: PublicKey, offerId: UInt64) {
        self.sellerId = sellerId
        self.offerId = offerId
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sellerId)
        try container.encode(offerId)
    }
}
