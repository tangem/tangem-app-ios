//
//  PolymarketABIWord.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum PolymarketABIWord {
    static let byteCount = 32
    static let digitCount = 2 * byteCount
    static let zero = String(repeating: "0", count: digitCount)

    static func address(_ address: String) -> String? {
        guard address.isEvmAddress else {
            return nil
        }

        return address.removeHexPrefix().lowercased().leftPadding(toLength: digitCount, withPad: "0")
    }

    static func uint(_ value: UInt64) -> String {
        String(value, radix: 16).leftPadding(toLength: digitCount, withPad: "0")
    }
}
