//
//  SolanaBorshReader.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

struct SolanaBorshReader {
    private let bytes: [UInt8]
    private(set) var offset: Int

    init(data: Data, offset: Int = 0) {
        bytes = [UInt8](data)
        self.offset = offset
    }

    var isAtEnd: Bool {
        offset >= bytes.count
    }

    mutating func readUInt8() throws -> UInt8 {
        try readBytes(count: 1)[0]
    }

    mutating func readBool() throws -> Bool {
        switch try readUInt8() {
        case 0: false
        case 1: true
        default: throw SolanaBorshReaderError.invalidBool
        }
    }

    mutating func readUInt16() throws -> UInt16 {
        UInt16(try readLittleEndian(byteCount: 2))
    }

    mutating func readUInt32() throws -> UInt32 {
        UInt32(try readLittleEndian(byteCount: 4))
    }

    mutating func readUInt64() throws -> UInt64 {
        try readLittleEndian(byteCount: 8)
    }

    mutating func readPublicKey() throws -> PublicKey {
        guard let key = PublicKey(bytes: try readBytes(count: PublicKey.LENGTH)) else {
            throw SolanaBorshReaderError.unexpectedEnd
        }

        return key
    }

    mutating func skipString() throws {
        _ = try readBytes(count: Int(try readUInt32()))
    }

    mutating func skip(byteCount: Int) throws {
        _ = try readBytes(count: byteCount)
    }

    mutating func readOption<Value>(_ readValue: (inout SolanaBorshReader) throws -> Value) throws -> Value? {
        switch try readUInt8() {
        case 0: return nil
        case 1: return try readValue(&self)
        default: throw SolanaBorshReaderError.invalidOptionTag
        }
    }

    mutating func readVector(_ readElement: (inout SolanaBorshReader) throws -> Void) throws {
        let count = try readUInt32()

        for _ in 0 ..< count {
            try readElement(&self)
        }
    }

    mutating func readBytes(count: Int) throws -> [UInt8] {
        guard count >= 0, count <= bytes.count - offset else {
            throw SolanaBorshReaderError.unexpectedEnd
        }

        defer { offset += count }

        return Array(bytes[offset ..< offset + count])
    }

    private mutating func readLittleEndian(byteCount: Int) throws -> UInt64 {
        try readBytes(count: byteCount)
            .enumerated()
            .reduce(UInt64(0)) { result, element in
                result | UInt64(element.element) << (8 * UInt64(element.offset))
            }
    }
}

enum SolanaBorshReaderError: Error, Equatable {
    case unexpectedEnd
    case invalidBool
    case invalidOptionTag
}
