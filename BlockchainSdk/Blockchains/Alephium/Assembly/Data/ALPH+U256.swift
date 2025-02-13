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

        func addUnsafe(_ that: U256) -> U256 {
            let underlying = v + that.v
            precondition(U256.validate(underlying), "Addition overflow")
            return U256.unsafe(underlying)
        }

        func add(_ that: U256) -> U256? {
            let underlying = v + that.v
            return U256.validate(underlying) ? U256.unsafe(underlying) : nil
        }

        func subUnsafe(_ that: U256) -> U256 {
            let underlying = v - that.v
            precondition(U256.validate(underlying), "Subtraction underflow")
            return U256.unsafe(underlying)
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

        func div(_ that: U256) -> U256? {
            return that.isZero ? nil : U256.unsafe(v / that.v)
        }

        static func < (lhs: U256, rhs: U256) -> Bool {
            return lhs.v < rhs.v
        }

        static func == (lhs: U256, rhs: U256) -> Bool {
            return lhs.v == rhs.v
        }

        func toByte() -> UInt8? {
            return v.bitWidth <= 7 ? UInt8(v) : nil
        }

        static let zero = U256.unsafe(BigUInt.zero)

        static func boundNonNegative(_ value: BigUInt) -> U256 {
            precondition(value.signum() >= 0, "Value must be non-negative")
            let raw = value.serialize()
            let boundedRaw = raw.count > 32 ? raw.suffix(32) : raw
            return U256.unsafe(BigUInt(Data(boundedRaw)))
        }

        static func boundSub(_ value: BigUInt) -> U256 {
            return value.signum() < 0 ? U256.unsafe(value + (BigUInt(1) << 256)) : U256.unsafe(value)
        }

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

        static func unsafe(_ bytes: Data) -> U256 {
            precondition(bytes.count == 32, "Byte array must be exactly 32 bytes")
            return U256(BigUInt(bytes))
        }

        static func from(_ bytes: Data) -> U256? {
            return from(BigUInt(bytes))
        }

        static func from(_ value: BigUInt) -> U256? {
            return validate(value) ? U256(value) : nil
        }
    }
}
