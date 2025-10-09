//
//  YieldModuleMarketsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import BigInt

protocol YieldModuleMarketsManager {
    var markets: [YieldModuleMarketInfo] { get }
    var marketsPublisher: AnyPublisher<[YieldModuleMarketInfo], Never> { get }

    func updateMarkets()
}

final class CommonYieldModuleMarketsManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let yieldMarketsRepository = CommonYieldModuleMarketsRepository()

    private let marketsSubject = CurrentValueSubject<[YieldModuleMarketInfo], Never>([])

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

            return response.tokens.compactMap {
                return YieldModuleMarketInfo(
                    tokenContractAddress: $0.tokenAddress,
                    apy: $0.apy,
                    isActive: $0.isActive,
                    chainId: $0.chainId
                )
            }
        } catch {
            guard let cachedMarkets = yieldMarketsRepository.markets() else {
                return []
            }

            return cachedMarkets.markets.compactMap {
                return YieldModuleMarketInfo(
                    tokenContractAddress: $0.tokenContractAddress,
                    apy: $0.apy,
                    isActive: $0.isActive,
                    chainId: $0.chainId
                )
            }
        }
    }

    func cacheMarkets(_ response: YieldModuleDTO.Response.MarketsInfo) {
        let marketsToStore = response.tokens.map {
            CachedYieldModuleMarket(
                tokenContractAddress: $0.tokenAddress,
                apy: $0.apy,
                isActive: $0.isActive,
                chainId: $0.chainId
            )
        }
        yieldMarketsRepository.store(
            markets: CachedYieldModuleMarkets(markets: marketsToStore, lastUpdated: response.lastUpdatedAt)
        )
    }
}

private extension CommonYieldModuleMarketsManager {
    enum Constants {
        static let temporaryDefaultMaxNetworkFee = BigUInt(1) // will be removed in the future [REDACTED_INFO]
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
