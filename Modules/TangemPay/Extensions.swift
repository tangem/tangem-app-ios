//
//  Extensions.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension Data {
    var hexString: String {
        return map { return String(format: "%02X", $0) }.joined()
    }

    init(hexString: String) {
        self = Data()
        reserveCapacity(hexString.unicodeScalars.lazy.underestimatedCount)

        var buffer: UInt8?
        let hasPrefix = hexString.range(of: "0x", options: [.anchored, .caseInsensitive]) != nil
        var skip = hasPrefix ? 2 : 0
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

private let hexPrefix = "0x"

extension String {
    func addHexPrefix() -> String {
        if lowercased().hasPrefix(hexPrefix) {
            return self
        }

        return hexPrefix.appending(self)
    }
}
