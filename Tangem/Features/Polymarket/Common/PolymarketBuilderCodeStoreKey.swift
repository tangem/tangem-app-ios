//
//  PolymarketBuilderCodeStoreKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPolymarket

private struct PolymarketBuilderCodeStoreKey: InjectionKey {
    static var currentValue = PolymarketBuilderCodeStore()
}

extension InjectedValues {
    var polymarketBuilderCodeStore: PolymarketBuilderCodeStore {
        get { Self[PolymarketBuilderCodeStoreKey.self] }
        set { Self[PolymarketBuilderCodeStoreKey.self] = newValue }
    }
}
