//
//  Int+.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

extension Int {
    var tlvBytes: [UInt8] {
        let byteBuffer: [UInt8] = [
            UInt8((self &  0x00FF00) >> 8),
            UInt8(self &  0x0000FF)]
        return byteBuffer
    }
    
    init?(from tlvBytes: [UInt8]?) {
        guard let bytes = tlvBytes else {
            return nil
        }
        let decimalValue = bytes.reduce(0) { v, byte in
            return v << 8 | Int(byte)
        }
        self = decimalValue
    }
    
    var bytes2: [UInt8] {
        let clamped = UInt16(clamping: self)
        let data = withUnsafeBytes(of: clamped) { Data($0) }
        return Array(data)
    }
    
    var byte: UInt8 {
        return UInt8(bitPattern: Int8(self))
    }
    
    var bytes4: [UInt8] {
        let clamped = UInt32(clamping: self)
        let data = withUnsafeBytes(of: clamped) { Data($0) }
        return Array(data)
    }
    
    var bytes8: [UInt8] {
        let data = withUnsafeBytes(of: self) { Data($0) }
        return Array(data)
    }
}
