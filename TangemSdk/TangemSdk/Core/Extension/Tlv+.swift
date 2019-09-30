//
//  Tlv+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension Tlv {
    /// Serialize TLV to Data
    var bytes: Data {
        var bytes = Data()
        let length = value.count
        bytes.reserveCapacity(1 + length)
        bytes.append(tagRaw)
        
        //serialize length
        if length > 0xFE { //long format
            bytes.append(0xFF)
            bytes.append(contentsOf: length.bytes2bigEndian)
        } else if length > 0 { //short format
            let lengthAsByte = length.byte
            bytes.append(lengthAsByte)
        } else {
            bytes.append(0x00)
        }
        
        //serialize data
        bytes.append(contentsOf: value)
        return bytes
    }
}
