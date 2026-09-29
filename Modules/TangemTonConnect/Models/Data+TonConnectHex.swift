//
//  Data+TonConnectHex.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension Data {
    /// Strict hex decoding: even length, `[0-9a-fA-F]` only, no `0x` prefix.
    init?(tonConnectHex hex: String) {
        let characters = Array(hex.utf8)
        guard characters.count % 2 == 0 else { return nil }

        var bytes = [UInt8]()
        bytes.reserveCapacity(characters.count / 2)

        var index = 0
        while index < characters.count {
            guard
                let high = Self.nibble(characters[index]),
                let low = Self.nibble(characters[index + 1])
            else {
                return nil
            }
            bytes.append(high << 4 | low)
            index += 2
        }

        self.init(bytes)
    }

    var tonConnectHexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    private static func nibble(_ character: UInt8) -> UInt8? {
        switch character {
        case UInt8(ascii: "0") ... UInt8(ascii: "9"): return character - UInt8(ascii: "0")
        case UInt8(ascii: "a") ... UInt8(ascii: "f"): return character - UInt8(ascii: "a") + 10
        case UInt8(ascii: "A") ... UInt8(ascii: "F"): return character - UInt8(ascii: "A") + 10
        default: return nil
        }
    }
}
