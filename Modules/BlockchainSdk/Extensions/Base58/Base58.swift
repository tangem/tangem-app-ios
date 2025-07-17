//
//  Base58.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// The Base58 encoding used is home made, and has some differences. Especially,
/// leading zeroes are kept as single zeroes when conversion happens.
public struct Base58 {
    private static let base58Alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

    private init() {}

    public static func encode(_ bytes: Data) -> String {
        var bytes = bytes
        var zerosCount = 0
        var length = 0

        for b in bytes {
            if b != 0 { break }
            zerosCount += 1
        }

        bytes.removeFirst(zerosCount)

        let size = bytes.count * 138 / 100 + 1

        var base58: [UInt8] = Array(repeating: 0, count: size)
        for b in bytes {
            var carry = Int(b)
            var i = 0

            for j in 0 ... base58.count - 1 where carry != 0 || i < length {
                carry += 256 * Int(base58[base58.count - j - 1])
                base58[base58.count - j - 1] = UInt8(carry % 58)
                carry /= 58
                i += 1
            }

            assert(carry == 0)

            length = i
        }

        // skip leading zeros
        var zerosToRemove = 0
        var str = ""
        for b in base58 {
            if b != 0 { break }
            zerosToRemove += 1
        }
        base58.removeFirst(zerosToRemove)

        while 0 < zerosCount {
            str = "\(str)1"
            zerosCount -= 1
        }

        for b in base58 {
            str = "\(str)\(base58Alphabet[String.Index(utf16Offset: Int(b), in: base58Alphabet)])"
        }

        return str
    }

    public static func decode(_ base58: String) -> Data {
        // remove leading and trailing whitespaces
        let string = base58.trimmingCharacters(in: .whitespacesAndNewlines)

        guard string.isNotEmpty else { return Data() }

        var zerosCount = 0
        var length = 0
        for c in string {
            if c != "1" { break }
            zerosCount += 1
        }

        let size = string.lengthOfBytes(using: .utf8) * 733 / 1000 + 1 - zerosCount

        guard size >= 0 else { return Data() }

        var base58: [UInt8] = Array(repeating: 0, count: size)
        for c in string where c != " " {
            // search for base58 character
            guard let base58Index = base58Alphabet.firstIndex(of: c) else { return Data() }

            var carry = base58Index.utf16Offset(in: base58Alphabet)
            var i = 0
            for j in 0 ... base58.count where carry != 0 || i < length {
                guard let currentByte = base58[safe: base58.count - j - 1] else {
                    return Data()
                }
                carry += 58 * Int(currentByte)

                // This is fine because of guard above
                base58[base58.count - j - 1] = UInt8(carry % 256)
                carry /= 256
                i += 1
            }

            assert(carry == 0)
            length = i
        }

        // skip leading zeros
        var zerosToRemove = 0

        for b in base58 {
            if b != 0 { break }
            zerosToRemove += 1
        }
        base58.removeFirst(zerosToRemove)

        return Data(repeating: 0, count: zerosCount) + Data(base58)
    }
}
