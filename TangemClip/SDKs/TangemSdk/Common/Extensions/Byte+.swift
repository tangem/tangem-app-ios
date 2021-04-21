//
//  Byte+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public typealias Byte = UInt8

extension UInt8 {
    public var description: String {
        return asHexString()
    }
    
    public func asHexString() -> String {
        return String(format: "%02X", self)
    }
}

extension UInt16 {
    public var description: String {
        return asHexString()
    }
    
    public func asHexString() -> String {
        return String(format: "%02X", self)
    }
}
