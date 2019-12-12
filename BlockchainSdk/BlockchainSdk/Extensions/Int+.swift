//
//  Int+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension Int {
    /// return 2 bytes of integer. LittleEndian format
    public var bytes2LE: Data {
        let clamped = UInt16(clamping: self)
        let data = withUnsafeBytes(of: clamped) { Data($0) }
        return data
    }
    
    /// return 4 bytes of integer. LittleEndian format
    public var bytes4LE: Data {
        let clamped = UInt32(clamping: self)
        let data = withUnsafeBytes(of: clamped) { Data($0) }
        return data
    }
    
    /// return 8 bytes of integer. LittleEndian  format
    public var bytes8LE: Data {
        let data = withUnsafeBytes(of: self) { Data($0) }
        return data
    }
}
