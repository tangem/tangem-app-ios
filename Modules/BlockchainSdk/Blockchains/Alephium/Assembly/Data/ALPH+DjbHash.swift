//
//  Alephium+DjbHash.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A struct representing the DJB hash function
    struct DjbHash {
        /// Hashes an array of bytes using the DJB hash function
        /// - Parameter bytes: The array of bytes to hash
        /// - Returns: The resulting hash value as an integer
        func intHash(_ bytes: [UInt8]) -> Int {
            var hash = 5381
            for byte in bytes {
                hash = ((hash << 5) &+ hash) &+ Int(byte)
            }
            return hash
        }
    }
}
