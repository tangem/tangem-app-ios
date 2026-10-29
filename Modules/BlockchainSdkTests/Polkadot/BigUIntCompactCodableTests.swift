//
//  BigUIntCompactCodableTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import ScaleCodec
import Testing
@testable import BlockchainSdk

@Suite("BigUInt SCALE compact encoding")
struct BigUIntCompactCodableTests {
    @Test(
        "A value that fits UInt64 encodes byte for byte like Compact<UInt64>",
        arguments: [UInt64(0), 1, 63, 64, 16383, 16384, (1 << 30) - 1, 1 << 30, 5_000_000_000, 200_000_000_000, UInt64.max]
    )
    func matchesUInt64Encoding(value: UInt64) throws {
        let expected = try encode(value, .compact)

        #expect(try encode(BigUInt(value), .compact) == expected)
    }

    @Test(
        "A value above UInt64 encodes in big-integer mode and decodes back",
        arguments: ["18450000000000000000", "100000000000000000000", "340282366920938463463374607431768211455"]
    )
    func roundTripAboveUInt64(decimalString: String) throws {
        let value = try #require(BigUInt(decimalString, radix: 10))

        let encoded = try encode(value, .compact)

        #expect(encoded.count == (value.bitWidth + 7) / 8 + 1)
        #expect(try decode(BigUInt.self, .compact, from: encoded) == value)
    }

    @Test("10^20 planck encodes as the nine-byte big-integer form")
    func hundredEnergyWebX() throws {
        let value = try #require(BigUInt("100000000000000000000", radix: 10))

        #expect(try encode(value, .compact).hex() == "17000010632d5ec76b05")
    }
}
