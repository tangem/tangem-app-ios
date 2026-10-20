//
//  WebSocketBackoff.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

public struct WebSocketBackoff: Sendable, Hashable {
    public static let `default` = WebSocketBackoff(base: .seconds(1), cap: .seconds(30))

    public let base: Duration
    public let cap: Duration

    public init(base: Duration, cap: Duration) {
        self.base = base
        self.cap = cap
    }

    func delay(forAttempt attempt: Int, random: (ClosedRange<Double>) -> Double = { Double.random(in: $0) }) -> Duration {
        let exponent = clamp(attempt - 1, min: 0, max: Constants.maximumExponent)
        let multiplier = 1 << exponent
        let ceiling = base > cap / multiplier ? cap : base * multiplier

        return ceiling * random(0 ... 1)
    }
}

// MARK: - Constants

private extension WebSocketBackoff {
    enum Constants {
        static let maximumExponent = 30
    }
}
