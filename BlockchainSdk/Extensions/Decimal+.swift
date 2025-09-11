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

    func exp(precision: Int) -> Decimal {
        var result = Decimal(1)
        var term = Decimal(1)
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
