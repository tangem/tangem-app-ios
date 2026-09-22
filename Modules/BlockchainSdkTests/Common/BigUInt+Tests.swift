//
//  BigUInt+.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Testing
import BigInt
import Foundation

struct BigUInt_ {
    @Test
    func hexString() {
        #expect(BigUInt(0).hexString == "0x0")
        #expect(BigUInt(10).power(18).hexString == "0xde0b6b3a7640000")
    }

    @Test
    func increasedByPercent() {
        #expect(BigUInt(21_000).increased(byPercent: 12) == 23_520)
        #expect(BigUInt(2_000).increased(byPercent: 5) == 2_100)
        #expect(BigUInt(3).increased(byPercent: 50) == 4)
    }

    @Test
    func decimalToBigUInt() throws {
        let decimalToBigUIntFormatted: (String) -> String = { string in
            let decimal = Decimal(string: string)
            #expect(decimal != nil)

            let bigUInt = BigUInt(decimal: decimal!)
            #expect(bigUInt != nil)

            return String(bigUInt!)
        }

        // Good numbers
        let validStrings = [
            "0",
            "1",
            "1234567890",
            "123456789012345678901234567890",
        ]
        for string in validStrings {
            #expect(string == decimalToBigUIntFormatted(string))
        }

        // Overflows
        let invalidStrings = [
            "123456789012345678901234567890123456789012345678901234567890",
        ]
        for string in invalidStrings {
            #expect(string != decimalToBigUIntFormatted(string))
        }

        // Corner cases
        #expect(BigUInt(decimal: -1) == nil)
        #expect(BigUInt(decimal: 1.5) == nil)
    }

    @Test
    func bigUIntToDecimal() throws {
        // Good numbers
        let validStrings: [String] = [
            "0",
            "1",
            "1234567890",
            "12345678901234567890",
            "1234567890123456789012345678901234567890",
        ]
        for string in validStrings {
            #expect(BigUInt(stringLiteral: string).decimal == Decimal(string: string))
        }

        // Overflows
        let invalidStrings = [
            "12345678901234567890123456789012345678901234567890123456789012345678901234567890",
        ]
        for string in invalidStrings {
            #expect(BigUInt(stringLiteral: string).decimal == nil)
        }
    }
}
