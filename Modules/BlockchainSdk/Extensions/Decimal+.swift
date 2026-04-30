//
//  Decimal+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension Decimal {
    func rounded(blockchain: Blockchain, roundingMode: RoundingMode = .down) -> Decimal {
        return rounded(scale: Int(blockchain.decimalCount), roundingMode: roundingMode)
    }

    /// Approximates the exponential function (e^x) for Decimal values using a Taylor series.
    /// - Parameter precision: The number of terms to use in the series (higher means more accuracy, default is 30).
    /// - Returns: The approximate value of e raised to the power of the Decimal.
    /// - Note: For very large or small values, accuracy may be limited. Increase `precision` for better results.
    func exp(precision: Int = 30) -> Decimal {
        var result = Decimal(string: "1")!
        var term = Decimal(string: "1")!
        var n = 1

        while n < precision {
            term *= self / Decimal(n)
            result += term
            n += 1

            if term == 0 { break }
        }
        return result
    }
}
