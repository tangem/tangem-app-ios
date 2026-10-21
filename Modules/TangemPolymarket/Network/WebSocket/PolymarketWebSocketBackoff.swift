//
//  PolymarketWebSocketBackoff.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum PolymarketWebSocketBackoff {
    static func delay(forAttempt attempt: Int, random: (ClosedRange<Double>) -> Double = { Double.random(in: $0) }) -> Duration {
        let exponent = min(max(attempt, 1) - 1, Constants.maximumExponent)
        let multiplier = 1 << exponent
        let ceiling = Constants.base > Constants.cap / multiplier ? Constants.cap : Constants.base * multiplier

        return ceiling * random(0 ... 1)
    }
}

// MARK: - Constants

private extension PolymarketWebSocketBackoff {
    enum Constants {
        static let base: Duration = .seconds(1)
        static let cap: Duration = .seconds(30)
        static let maximumExponent = 30
    }
}
