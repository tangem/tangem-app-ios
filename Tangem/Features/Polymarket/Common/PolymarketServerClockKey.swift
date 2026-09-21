//
//  PolymarketServerClockKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPolymarket

private struct PolymarketServerClockKey: InjectionKey {
    static var currentValue = PolymarketServerClock()
}

extension InjectedValues {
    var polymarketServerClock: PolymarketServerClock {
        get { Self[PolymarketServerClockKey.self] }
        set { Self[PolymarketServerClockKey.self] = newValue }
    }
}
