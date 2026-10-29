//
//  YieldModePromoCatalogProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol YieldModePromoCatalogProvider {
    var catalogPublisher: AnyPublisher<YieldModePromoCatalog, Never> { get }
}

struct CommonYieldModePromoCatalogProvider: YieldModePromoCatalogProvider {
    @Injected(\.yieldModuleNetworkManager) private var yieldModuleNetworkManager: YieldModuleNetworkManager

    var catalogPublisher: AnyPublisher<YieldModePromoCatalog, Never> {
        Publishers.CombineLatest(yieldModuleNetworkManager.marketsLoadStatePublisher, yieldModuleNetworkManager.marketsPublisher)
            .map { YieldModePromoCatalog(loadState: $0, markets: $1) }
            .eraseToAnyPublisher()
    }
}

// MARK: - YieldModePromoCatalog

struct YieldModePromoCatalog: Equatable {
    let loadState: YieldModuleMarketsLoadState
    let markets: [YieldModuleMarketInfo]
}
