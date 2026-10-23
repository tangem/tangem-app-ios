//
//  U256.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension ALPH {
    struct U256: Comparable {
        let v: BigUInt

        init(_ v: BigUInt) {
            precondition(U256.validate(v), "Invalid U256 value")
            self.v = v
        }

        var isZero: Bool {
            return v.isZero
        }

        func add(_ that: U256) -> U256? {
            let underlying = v + that.v
            return U256.validate(underlying) ? U256.unsafe(underlying) : nil
        }

        func sub(_ that: U256) -> U256? {
            let underlying = v - that.v
            return U256.validate(underlying) ? U256.unsafe(underlying) : nil
        }

        func mulUnsafe(_ that: U256) -> U256 {
            let underlying = v * that.v
            precondition(U256.validate(underlying), "Multiplication overflow")
            return U256.unsafe(underlying)
        }

        static func < (lhs: U256, rhs: U256) -> Bool {
            return lhs.v < rhs.v
        }

        static func == (lhs: U256, rhs: U256) -> Bool {
            return lhs.v == rhs.v
        }

        static let zero = U256.unsafe(BigUInt.zero)

        static func validate(_ value: BigUInt) -> Bool {
            return value.signum() >= 0 && value.bitWidth <= 256
        }

        static func unsafe(_ value: BigUInt) -> U256 {
            precondition(validate(value), "Invalid U256 value")
            return U256(value)
        }

        static func unsafe(_ value: Int) -> U256 {
            return unsafe(BigUInt(value))
        }

        static func unsafe(_ value: UInt64) -> U256 {
            return U256(BigUInt(value))
        }

        static func from(_ bytes: Data) -> U256? {
            return from(BigUInt(bytes))
        }

        static func from(_ value: BigUInt) -> U256? {
            return validate(value) ? U256(value) : nil
        }
    }
}
