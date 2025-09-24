//
//  YieldModuleMarketsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol YieldModuleMarketsManager {
    var markets: [YieldModuleMarketInfo] { get }
    var marketsPublisher: AnyPublisher<[YieldModuleMarketInfo], Never> { get }

    func updateMarkets()
}

final class CommonYieldModuleMarketsManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let yieldMarketsStorage = CommonYieldModuleMarketsStorage()

    private let marketsSubject = CurrentValueSubject<[YieldModuleMarketInfo], Never>([])
    private var cancellable: AnyCancellable?

    init() {}
}

extension CommonYieldModuleMarketsManager: YieldModuleMarketsManager {
    var markets: [YieldModuleMarketInfo] {
        marketsSubject.value
    }

    var marketsPublisher: AnyPublisher<[YieldModuleMarketInfo], Never> {
        marketsSubject.eraseToAnyPublisher()
    }

    func updateMarkets() {
        Task { @MainActor in
            let markets = await fetchMarkets()
            marketsSubject.send(markets)
        }
    }
}

private extension CommonYieldModuleMarketsManager {
    func fetchMarkets() async -> [YieldModuleMarketInfo] {
        do {
            let response = try await tangemApiService.getYieldMarkets()

            cacheMarkets(response)

            return response.markets.map {
                YieldModuleMarketInfo(
                    tokenContractAddress: $0.tokenAddress,
                    apy: $0.apy,
                    isActive: $0.isActive
                )
            }
        } catch {
            guard let cachedMarkets = yieldMarketsStorage.markets() else {
                return []
            }

            return cachedMarkets.markets.map {
                YieldModuleMarketInfo(
                    tokenContractAddress: $0.tokenContractAddress,
                    apy: $0.apy,
                    isActive: $0.isActive
                )
            }
        }
    }

    func cacheMarkets(_ response: YieldModuleDTO.Response.MarketsInfo) {
        let marketsToStore = response.markets.map {
            CachedYieldModuleMarket(tokenContractAddress: $0.tokenAddress, apy: $0.apy, isActive: $0.isActive)
        }
        yieldMarketsStorage.store(
            markets: CachedYieldModuleMarkets(markets: marketsToStore, lastUpdated: response.lastUpdated)
        )
    }
}

private extension CommonYieldModuleMarketsManager {
    enum Constants {
        static let fetchInterval: TimeInterval = 30
    }
}

private struct YieldModuleMarketsManagerKey: InjectionKey {
    static var currentValue: YieldModuleMarketsManager = CommonYieldModuleMarketsManager()
}

extension InjectedValues {
    var yieldModuleMarketsManager: YieldModuleMarketsManager {
        get { Self[YieldModuleMarketsManagerKey.self] }
        set { Self[YieldModuleMarketsManagerKey.self] = newValue }
    }
}
