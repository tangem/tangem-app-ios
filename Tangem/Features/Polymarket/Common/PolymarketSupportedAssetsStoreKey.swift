//
//  PolymarketSupportedAssetsStoreKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPolymarket

private struct PolymarketSupportedAssetsStoreKey: InjectionKey {
    static var currentValue = PolymarketSupportedAssetsStore()
}

extension InjectedValues {
    var polymarketSupportedAssetsStore: PolymarketSupportedAssetsStore {
        get { Self[PolymarketSupportedAssetsStoreKey.self] }
        set { Self[PolymarketSupportedAssetsStoreKey.self] = newValue }
    }
}
