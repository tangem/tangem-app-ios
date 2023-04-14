//
//  Data+.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Data {
    init(hexString: String) {
        self = Data()
        reserveCapacity(hexString.unicodeScalars.lazy.underestimatedCount)

        var buffer: UInt8?
        var skip = hexString.hasPrefix("0x") ? 2 : 0
        for char in hexString.unicodeScalars.lazy {
            guard skip == 0 else {
                skip -= 1
                continue
            }
            guard char.value >= 48, char.value <= 102 else {
                removeAll()
                return
            }
            let v: UInt8
            let c = UInt8(char.value)
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                removeAll()
                return
            }
            if let b = buffer {
                append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        if let b = buffer {
            append(b)
        }
    }
}
