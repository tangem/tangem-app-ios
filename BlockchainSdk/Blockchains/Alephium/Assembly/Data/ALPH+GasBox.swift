//
//  Alephium+GasBox.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension ALPH {
    // Define the GasBox struct
    struct GasBox: Comparable {
        let value: Int

        // Use gas and return a Result
        func use(amount: GasBox) throws -> GasBox {
            if self >= amount {
                return GasBox(value: value - amount.value)
            } else {
                throw GasBoxError.outOfGas
            }
        }

        // Convert to U256 (assuming U256 is a custom type)
        func toU256() -> U256 {
            return U256.unsafe(BigUInt(value))
        }

        // Comparable conformance
        static func < (lhs: GasBox, rhs: GasBox) -> Bool {
            return lhs.value < rhs.value
        }

        static func == (lhs: GasBox, rhs: GasBox) -> Bool {
            return lhs.value == rhs.value
        }

        // Unsafe initializer
        static func unsafe(initialGas: Int) -> GasBox {
            precondition(initialGas >= 0, "Initial gas must be non-negative")
            return GasBox(value: initialGas)
        }

        // MARK: - Serde

        static var serde: ALPH.AnySerde<ALPH.GasBox> {
            IntSerde().xmap(to: { GasBox(value: $0) }, from: { $0.value })
        }
    }

    // MARK: - Errors

    enum GasBoxError: LocalizedError {
        case negativeGas
        case outOfGas
    }
}
