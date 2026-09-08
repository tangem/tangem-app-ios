//
//  PolymarketSupportedAssetsStore.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public final class PolymarketSupportedAssetsStore {
    private let assets = OSAllocatedUnfairLock(initialState: [PolymarketSupportedAsset]?.none)

    public init() {}

    public func cachedAssets() -> [PolymarketSupportedAsset]? {
        assets.withLock { $0 }
    }

    public func store(_ assets: [PolymarketSupportedAsset]) {
        self.assets.withLock { $0 = assets }
    }
}
