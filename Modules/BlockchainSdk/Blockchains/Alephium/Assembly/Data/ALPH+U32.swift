//
//  U32.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension ALPH {
    struct U32: Comparable {
        let v: UInt32

        var isZero: Bool {
            return v == 0
        }

        func addUnsafe(_ that: U32) -> U32 {
            let underlying = v &+ that.v
            precondition(U32.checkAdd(self, underlying))
            return U32.unsafe(underlying)
        }

        func add(_ that: U32) -> U32? {
            let underlying = v &+ that.v
            return U32.checkAdd(self, underlying) ? U32.unsafe(underlying) : nil
        }

        func subUnsafe(_ that: U32) -> U32 {
            precondition(U32.checkSub(self, that))
            return U32.unsafe(v &- that.v)
        }

        func sub(_ that: U32) -> U32? {
            return U32.checkSub(self, that) ? U32.unsafe(v &- that.v) : nil
        }

        func mulUnsafe(_ that: U32) -> U32 {
            if v == 0 { return U32.Zero }
            let underlying = v &* that.v
            precondition(U32.checkMul(self, that, underlying))
            return U32.unsafe(underlying)
        }

        func mul(_ that: U32) -> U32? {
            if v == 0 { return U32.Zero }
            let underlying = v &* that.v
            return U32.checkMul(self, that, underlying) ? U32.unsafe(underlying) : nil
        }

        func divUnsafe(_ that: U32) -> U32 {
            precondition(!that.isZero)
            return U32.unsafe(v / that.v)
        }

        func div(_ that: U32) -> U32? {
            return that.isZero ? nil : U32.unsafe(v / that.v)
        }

        func modUnsafe(_ that: U32) -> U32 {
            precondition(!that.isZero)
            return U32.unsafe(v % that.v)
        }

        func mod(_ that: U32) -> U32? {
            return that.isZero ? nil : U32.unsafe(v % that.v)
        }

        func toBigInt() -> BigUInt {
            return BigUInt(v)
        }

        static func < (lhs: U32, rhs: U32) -> Bool {
            return lhs.v < rhs.v
        }

        static func == (lhs: U32, rhs: U32) -> Bool {
            return lhs.v == rhs.v
        }

        static let Zero = U32.unsafe(0)
        static let One = U32.unsafe(1)
        static let Two = U32.unsafe(2)
        static let MaxValue = U32.unsafe(UInt32.max)
        static let MinValue = U32.Zero

        static func validate(_ value: BigUInt) -> Bool {
            return value.bitWidth <= 32
        }

        static func unsafe(_ value: UInt32) -> U32 {
            return U32(v: value)
        }

        static func from(_ value: Int) -> U32? {
            return value >= 0 && value <= Int(UInt32.max) ? U32.unsafe(UInt32(value)) : nil
        }

        static func from(_ value: BigUInt) -> U32? {
            return validate(value) ? U32.unsafe(UInt32(value)) : nil
        }

        private static func checkAdd(_ a: U32, _ c: UInt32) -> Bool {
            return c >= a.v
        }

        private static func checkSub(_ a: U32, _ b: U32) -> Bool {
            return a.v >= b.v
        }

        private static func checkMul(_ a: U32, _ b: U32, _ c: UInt32) -> Bool {
            return c / a.v == b.v
        }
    }
}
