//
//  VariantIntEncoder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Bitcoin/PSBT CompactSize varint encoder.
///
/// This encoding is used throughout Bitcoin-style formats (including PSBT) to prefix variable-length fields
/// such as scripts and key/value sizes.
enum VariantIntEncoder {
    /// Encodes a value using Bitcoin/PSBT CompactSize varint (aka "varint") format.
    ///
    /// Encoding:
    /// - `0 ..< 0xFD`: 1 byte (the value itself)
    /// - `0xFD ..< 0x1_0000`: `0xFD` + `UInt16` little-endian (3 bytes total)
    /// - `0x1_0000 ..< 0x1_0000_0000`: `0xFE` + `UInt32` little-endian (5 bytes total)
    /// - `>= 0x1_0000_0000`: `0xFF` + `UInt64` little-endian (9 bytes total)
    ///
    /// - Parameter value: Unsigned integer to encode.
    /// - Returns: Bytes representing `value` in CompactSize varint encoding.
    static func encode(_ value: UInt64) -> Data {
        switch value {
        case 0 ..< 0xFD:
            return Data([UInt8(value)])
        case 0xFD ..< 0x1_0000:
            var v = UInt16(value).littleEndian
            return Data([0xFD]) + withUnsafeBytes(of: &v) { Data($0) }
        case 0x1_0000 ..< 0x1_0000_0000:
            var v = UInt32(value).littleEndian
            return Data([0xFE]) + withUnsafeBytes(of: &v) { Data($0) }
        default:
            var v = UInt64(value).littleEndian
            return Data([0xFF]) + withUnsafeBytes(of: &v) { Data($0) }
        }
    }
}
