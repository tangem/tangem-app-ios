//
//  TransactionEnvelopeXDR.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum EnvelopeType: Int32 {
    case typeSCP = 1
    case typeTX = 2
    case typeAUTH = 3
}

public class TransactionEnvelopeXDR: NSObject, XDRCodable {
    public let tx: TransactionXDR
    public var signatures: [DecoratedSignatureXDR]
    
    public init(tx: TransactionXDR, signatures: [DecoratedSignatureXDR]) {
        self.tx = tx
        self.signatures = signatures
    }
    
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        tx = try container.decode(TransactionXDR.self)
        signatures = try decodeArray(type: DecoratedSignatureXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(tx)
        try container.encode(signatures)
    }
    
}
