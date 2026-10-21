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

        static func < (lhs: U32, rhs: U32) -> Bool {
            return lhs.v < rhs.v
        }

        static func == (lhs: U32, rhs: U32) -> Bool {
            return lhs.v == rhs.v
        }

        static let Zero = U32.unsafe(0)

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
    }
}
