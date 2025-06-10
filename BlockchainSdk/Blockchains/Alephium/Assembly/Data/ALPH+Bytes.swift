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
        static func from64(_ value: Int) -> Data {
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

        /// Converts a Data object to an integer value with 8 bytes
        /// - Parameter bytes: The Data object to convert
        /// - Returns: The integer value represented by the bytes
        static func toLongUnsafe(_ bytes: Data) -> Int64 {
            precondition(bytes.count == 8, "Byte array must have exactly 8 bytes")
            return (Int64(bytes[0]) & 0xff) << 56 |
                (Int64(bytes[1]) & 0xff) << 48 |
                (Int64(bytes[2]) & 0xff) << 40 |
                (Int64(bytes[3]) & 0xff) << 32 |
                (Int64(bytes[4]) & 0xff) << 24 |
                (Int64(bytes[5]) & 0xff) << 16 |
                (Int64(bytes[6]) & 0xff) << 8 |
                (Int64(bytes[7]) & 0xff)
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

        /// Performs a bitwise XOR operation on the bytes of an integer value
        /// - Parameter value: The integer value to XOR the bytes of
        /// - Returns: The result of the XOR operation on the bytes of the integer value
        static func xorByte(_ value: Int) -> UInt8 {
            let byte0 = UInt8(truncatingIfNeeded: value >> 24)
            let byte1 = UInt8(truncatingIfNeeded: value >> 16)
            let byte2 = UInt8(truncatingIfNeeded: value >> 8)
            let byte3 = UInt8(truncatingIfNeeded: value)
            return byte0 ^ byte1 ^ byte2 ^ byte3
        }
    }
}
