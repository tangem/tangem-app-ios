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
    /// Define the GasBox struct
    struct GasBox: Comparable {
        let value: Int

        /// Convert to U256 (assuming U256 is a custom type)
        func toU256() -> U256 {
            return U256.unsafe(BigUInt(value))
        }

        /// Comparable conformance
        static func < (lhs: GasBox, rhs: GasBox) -> Bool {
            return lhs.value < rhs.value
        }

        static func == (lhs: GasBox, rhs: GasBox) -> Bool {
            return lhs.value == rhs.value
        }

        /// Unsafe initializer
        static func unsafe(initialGas: Int) -> GasBox {
            precondition(initialGas >= 0, "Initial gas must be non-negative")
            return GasBox(value: initialGas)
        }

        // MARK: - Serde

        static var serde: ALPH.AnySerde<ALPH.GasBox> {
            IntSerde().xmap(to: { GasBox(value: $0) }, from: { $0.value })
        }
    }
}
