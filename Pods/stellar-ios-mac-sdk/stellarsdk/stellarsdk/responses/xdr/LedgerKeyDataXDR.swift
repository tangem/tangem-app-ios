//
//  LedgerKeyData.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct LedgerKeyDataXDR: XDRCodable {
    let accountId: PublicKey
    let dataName: String
    
    init(accountId: PublicKey, dataName: String) {
        self.accountId = accountId
        self.dataName = dataName
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(accountId)
        try container.encode(dataName)
    }
}
