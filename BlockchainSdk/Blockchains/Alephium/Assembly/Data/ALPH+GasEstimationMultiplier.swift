//
//  ALPH+GasEstimationMulti.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct GasEstimationMultiplier {
        private let value: Double

        private init(value: Double) {
            self.value = value
        }

        static let maxPrecision: Int = 2
        static let denominator: Int = .init(pow(10.0, Double(maxPrecision)))

        func multiplied(by gas: GasBox) -> GasBox {
            let numerator = Int(value * Double(Self.denominator))
            return GasBox.unsafe(initialGas: gas.value * numerator / Self.denominator)
        }

        static func from(_ multiplier: Double?) throws -> GasEstimationMultiplier? {
            guard let multiplier = multiplier else {
                return nil
            }

            let precision = multiplierStringPrecision(multiplier)

            if precision > maxPrecision {
                throw MultiplierError.invalidGasEstimationMultiplierPrecision(max: maxPrecision)
            }

            return GasEstimationMultiplier(value: multiplier)
        }

        private static func multiplierStringPrecision(_ multiplier: Double) -> Int {
            let str = String(multiplier)
            if let dotIndex = str.firstIndex(of: ".") {
                return str.distance(from: dotIndex, to: str.endIndex) - 1
            }
            return 0
        }
    }

    // MARK: - Error

    enum MultiplierError: LocalizedError {
        case invalidGasEstimationMultiplier
        case invalidGasEstimationMultiplierPrecision(max: Int)

        var errorDescription: String? {
            switch self {
            case .invalidGasEstimationMultiplier:
                return "Invalid gas estimation multiplier, expected a value between [1.0, 2.0]"
            case .invalidGasEstimationMultiplierPrecision(let max):
                return "Invalid gas estimation multiplier precision, maximum allowed precision is \(max)"
            }
        }
    }
}
