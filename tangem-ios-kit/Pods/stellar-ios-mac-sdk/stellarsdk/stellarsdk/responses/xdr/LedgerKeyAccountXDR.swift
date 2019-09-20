//
//  LedgerKeyAccountXDR.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct LedgerKeyAccountXDR: XDRCodable {
    let accountID: PublicKey
    
    init(accountID: PublicKey) {
        self.accountID = accountID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(accountID)
    }
}
