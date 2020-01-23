//
//  TlvBuilder.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class TlvBuilder {
    /// Fix nfc issues with long-running commands and security delay for iPhone 7/7+. Card firmware 2.39
    /// 4 - Timeout setting for ping nfc-module
    private static let legacyModeTlv = Tlv(.legacyMode, value: Data([Byte(4)]))
    
    private var tlv = [Tlv]()
    private let encoder = TlvEncoder()
    
    public func append<TValue>(_ tag: TlvTag, value: TValue) throws {
        tlv.append(try encoder.encode(tag, value: value))
    }
    
    public func serialize(legacyMode: Bool?) -> Data {
        if legacyMode ?? false {
            tlv.append(TlvBuilder.legacyModeTlv)
        }
        
        return tlv.serialize()
    }
}
