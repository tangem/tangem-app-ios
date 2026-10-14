//
//  ALPH+Bytes.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A utility enum for handling byte operations
    enum Bytes {
        /// Converts an integer value to a Data object
        /// - Parameter value: The integer value to convert
        /// - Returns: A Data object containing the bytes of the integer value
        static func from(_ value: Int) -> Data {
            return Data([
                UInt8(truncatingIfNeeded: value >> 24),
                UInt8(truncatingIfNeeded: value >> 16),
                UInt8(truncatingIfNeeded: value >> 8),
                UInt8(truncatingIfNeeded: value),
            ])
        }

        /// Converts a Data object to an integer value
        /// - Parameter bytes: The Data object to convert
        /// - Returns: The integer value represented by the bytes
        static func toIntUnsafe(_ bytes: Data) -> Int {
            precondition(bytes.count == 4, "Byte array must have exactly 4 bytes")
            return (Int(bytes[0]) << 24) |
                ((Int(bytes[1]) & 0xff) << 16) |
                ((Int(bytes[2]) & 0xff) << 8) |
                (Int(bytes[3]) & 0xff)
        }

        /// Converts an integer value to a Data object with 8 bytes
        /// - Parameter value: The integer value to convert
        /// - Returns: A Data object containing the bytes of the integer value
        static func from(_ value: Int64) -> Data {
            return Data([
                UInt8(truncatingIfNeeded: value >> 56),
                UInt8(truncatingIfNeeded: value >> 48),
                UInt8(truncatingIfNeeded: value >> 40),
                UInt8(truncatingIfNeeded: value >> 32),
                UInt8(truncatingIfNeeded: value >> 24),
                UInt8(truncatingIfNeeded: value >> 16),
                UInt8(truncatingIfNeeded: value >> 8),
                UInt8(truncatingIfNeeded: value),
            ])
        }
    }
}
