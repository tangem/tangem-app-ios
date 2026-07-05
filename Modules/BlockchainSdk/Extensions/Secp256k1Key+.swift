//
//  Secp256k1Key+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension Secp256k1Key {
    enum KeyType {
        case compressed
        case extended

        var size: Int {
            switch self {
            case .compressed: 33
            case .extended: 65
            }
        }
    }

    public static func isCompressed(publicKey: Data) -> Bool {
        publicKey.count == KeyType.compressed.size
    }

    static func isExtended(publicKey: Data) -> Bool {
        publicKey.count == KeyType.extended.size
    }
}
