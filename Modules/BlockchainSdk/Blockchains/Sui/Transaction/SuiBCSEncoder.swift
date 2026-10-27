//
//  SuiBCSEncoder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol SuiBCSEncodable {
    func encode(to encoder: inout SuiBCSEncoder)
}

struct SuiBCSEncoder {
    private(set) var data = Data()

    mutating func encode<T: FixedWidthInteger>(_ value: T) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }

    mutating func encode<T: FixedWidthInteger>(_ value: T?) {
        guard let value else {
            encode(Constants.optionNone)
            return
        }

        encode(Constants.optionSome)
        encode(value)
    }

    mutating func encodeVariant(_ index: Int) {
        encodeLength(index)
    }

    mutating func encode(fixedBytes: Data) {
        data.append(fixedBytes)
    }

    mutating func encode(bytes: Data) {
        encodeLength(bytes.count)
        data.append(bytes)
    }

    mutating func encode(_ string: String) {
        encode(bytes: Data(string.utf8))
    }

    mutating func encode(_ value: some SuiBCSEncodable) {
        value.encode(to: &self)
    }

    mutating func encode(_ values: [some SuiBCSEncodable]) {
        encodeLength(values.count)
        values.forEach { $0.encode(to: &self) }
    }

    private mutating func encodeLength(_ length: Int) {
        var value = UInt64(length)

        repeat {
            var byte = UInt8(value & 0x7F)
            value >>= 7

            if value != 0 {
                byte |= 0x80
            }

            data.append(byte)
        } while value != 0
    }
}

// MARK: - Constants

private extension SuiBCSEncoder {
    enum Constants {
        static let optionNone: UInt8 = 0
        static let optionSome: UInt8 = 1
    }
}
