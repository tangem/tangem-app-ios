//
//  Int+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension Int {
    /// Convert TLV-length to Integer
    /// - Parameter lengthValue: length bytes from TLV-format
    init?(lengthValue: Data) {
        let value = lengthValue.reduce(0) { v, byte in
            return v << 8 | Int(byte)
        }
        self = value
    }
    
    /// Convert int to byte, truncatingIfNeeded
    var byte: Byte {
        return Byte(truncatingIfNeeded: self)
    }
    
    /// return 2 bytes of integer. little Endian format
    var bytes2: Data {
        let clamped = UInt16(clamping: self)
        let data = withUnsafeBytes(of: clamped) { Data($0) }
        return data
    }
    
    /// return 2 bytes of integer in bigEndian format. Used for TLV serialization
    var bytes2bigEndian: Data {
        let clamped = UInt16(clamping: self).bigEndian
        let data = withUnsafeBytes(of: clamped) { Data($0) }
        return data
    }
    
    /// return 4 bytes of integer. little Endian format
    var bytes4: Data {
        let clamped = UInt32(clamping: self)
        let data = withUnsafeBytes(of: clamped) { Data($0) }
        return data
    }
    
    /// return 8 bytes of integer. little Endian format
    var bytes8: Data {
        let data = withUnsafeBytes(of: self) { Data($0) }
        return data
    }
}
