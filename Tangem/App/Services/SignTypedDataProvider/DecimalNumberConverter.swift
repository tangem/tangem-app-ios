//
//  DecimalNumberConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import web3swift
import BigInt

public protocol DecimalNumberConverting {
    func bigUIntValue(value: Decimal, decimalCount: Int) -> BigUInt?
    func encoded(value: Decimal, decimalCount: Int) -> Data?
}

struct DecimalNumberConverter {}

// MARK: - DecimalNumberConverting

extension DecimalNumberConverter: DecimalNumberConverting {
    func bigUIntValue(value: Decimal, decimalCount: Int) -> BigUInt? {
        if value == 0 {
            return BigUInt.zero
        }

        if value == Decimal.greatestFiniteMagnitude {
            return BigUInt(2).power(256) - 1
        }

        return Web3.Utils.parseToBigUInt("\(value)", decimals: decimalCount)
    }

    func encoded(value: Decimal, decimalCount: Int) -> Data? {
        guard let bigUIntValue = bigUIntValue(value: value, decimalCount: decimalCount) else {
            return nil
        }

        let amountData = bigUIntValue.serialize()
        return amountData
    }

//    func encodedForSend(value: Decimal, decimalCount: Int) -> String? {
//        if isZero {
//            return "0x0"
//        }
//
//        return encoded?.hexString.stripLeadingZeroes().addHexPrefix()
//    }
//    func encodedAligned(value: Decimal, decimalCount: Int) -> Data? {
//        encoded?.aligned()
//    }
}
