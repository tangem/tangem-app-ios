//
//  TlvBuilder.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class TlvBuilder {
    private var tlv = [Tlv]()
    private let encoder = TlvEncoder()
    
    public func append<TValue>(_ tag: TlvTag, value: TValue) throws {
        tlv.append(try encoder.encode(tag, value: value))
    }
    
    public func serialize() -> Data {
        return tlv.serialize()
    }
}
