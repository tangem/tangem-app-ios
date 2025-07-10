//
//  Alephium+Constants.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension ALPH {
    enum Constants {
        static let quintillion: BigUInt = 10_000_000_000_000_000
        static let billion: BigUInt = 1_000_000_000

        static let coinInOneALPH: U256 = .unsafe(quintillion)
        static let coinInOneNanoALPH: U256 = .unsafe(billion)

        static let maxALPHValue: U256 = .unsafe(billion).mulUnsafe(coinInOneALPH)

        static let maxTxInputNum: Int = 256
        static let maxTxOutputNum: Int = 256

        static let dustAmountValue = Decimal(stringValue: "0.001")!

        static let minimalGasBox: GasBox = .unsafe(initialGas: minimalGas)
        static let nonCoinbaseMinValue: Decimal = .init(stringValue: "100")!

        static var nonCoinbaseMinGasPrice: GasPrice {
            let u256 = Constants.nanoALPH(amount: nonCoinbaseMinValue.uint64Value)
            return GasPrice(value: u256)
        }

        static var dustUtxoAmount: U256 {
            Constants.nanoALPH(amount: dustAmountValue.uint64Value)
        }

        static func nanoALPH(amount: UInt64) -> U256 {
            precondition(amount >= 0, "Amount must be non-negative")
            return U256.unsafe(amount).mulUnsafe(coinInOneNanoALPH)
        }

        static let inputBaseGas: Int = 2000
        static let outputBaseGas: Int = 4500
        static let baseGas: Int = 1000
        static let p2pkUnlockGas: Int = 2060
        static let minimalGas: Int = 20000
    }
}
