//
//  OperationMetaXDR.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct OperationMetaXDR: XDRCodable {
    public let changes: LedgerEntryChangesXDR
    
    public init(changes: LedgerEntryChangesXDR) {
        self.changes = changes
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        changes = try container.decode(LedgerEntryChangesXDR.self)
     }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(changes)
    }
}
