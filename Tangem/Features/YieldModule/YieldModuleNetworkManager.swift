//
//  YieldModuleNetworkManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import BigInt
import TangemFoundation

protocol YieldModuleNetworkManager {
    var markets: [YieldModuleMarketInfo] { get }
    var marketsPublisher: AnyPublisher<[YieldModuleMarketInfo], Never> { get }

    func updateMarkets(chainIDs: [String])

    func fetchYieldTokenInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleTokenInfo
    func fetchChartData(tokenContractAddress: String, chainId: Int) async throws -> YieldChartData
    func activate(tokenContractAddress: String, walletAddress: String, chainId: Int, userWalletId: String) async throws
    func deactivate(tokenContractAddress: String, walletAddress: String, chainId: Int) async throws
}

final class CommonYieldModuleNetworkManager {
    private let yieldModuleAPIService: YieldModuleAPIService
    private let yieldMarketsRepository: YieldModuleMarketsRepository
    private let yieldModuleChartManager: YieldModuleChartManager

    private let marketsSubject = CurrentValueSubject<[YieldModuleMarketInfo], Never>([])

    init(
        yieldModuleAPIService: YieldModuleAPIService,
        yieldMarketsRepository: YieldModuleMarketsRepository,
        yieldModuleChartManager: YieldModuleChartManager
    ) {
        self.yieldModuleAPIService = yieldModuleAPIService
        self.yieldMarketsRepository = yieldMarketsRepository
        self.yieldModuleChartManager = yieldModuleChartManager
    }
}

extension CommonYieldModuleNetworkManager: YieldModuleNetworkManager {
    var markets: [YieldModuleMarketInfo] {
        marketsSubject.value
    }

    var marketsPublisher: AnyPublisher<[YieldModuleMarketInfo], Never> {
        marketsSubject.eraseToAnyPublisher()
    }

    func updateMarkets(chainIDs: [String]) {
        Task { @MainActor in
            let markets = await fetchMarkets(chainIDs: chainIDs)
            marketsSubject.send(markets)
        }
    }

    func fetchYieldTokenInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleTokenInfo {
        let position = try await yieldModuleAPIService.getTokenPositionInfo(
            tokenContractAddress: tokenContractAddress,
            chainId: chainId
        )

        return YieldModuleTokenInfo(
            isActive: position.isActive,
            apy: position.apy,
            maxFeeNative: position.maxFeeNative,
            maxFeeUSD: position.maxFeeUSD
        )
    }

    func fetchChartData(tokenContractAddress: String, chainId: Int) async throws -> YieldChartData {
        let chartData = try await yieldModuleAPIService.getChart(
            tokenContractAddress: tokenContractAddress,
            chainId: chainId,
            window: .lastYear,
            bucketSizeDays: nil
        )

        return YieldChartData(
            buckets: chartData.data.map { $0.avgApy.doubleValue },
            averageApy: chartData.avr,
            maxApy: chartData.data.map { $0.avgApy.doubleValue }.max() ?? 0,
            xLabels: yieldModuleChartManager.makeMonthLabels(from: chartData.from, to: chartData.to, bucketsCount: chartData.data.count)
        )
    }

    func activate(tokenContractAddress: String, walletAddress: String, chainId: Int, userWalletId: String) async throws {
        try await yieldModuleAPIService.activate(
            tokenContractAddress: tokenContractAddress,
            walletAddress: walletAddress,
            chainId: chainId,
            userWalletId: userWalletId
        )
    }

    func deactivate(tokenContractAddress: String, walletAddress: String, chainId: Int) async throws {
        try await yieldModuleAPIService.deactivate(
            tokenContractAddress: tokenContractAddress,
            walletAddress: walletAddress,
            chainId: chainId
        )
    }
}

private extension CommonYieldModuleNetworkManager {
    func fetchMarkets(chainIDs: [String]) async -> [YieldModuleMarketInfo] {
        do {
            let response = try await yieldModuleAPIService.getYieldMarkets(chainIDs: chainIDs)

            cacheMarkets(response)

            return response.tokens.compactMap {
                return YieldModuleMarketInfo(
                    tokenContractAddress: $0.tokenAddress,
                    apy: $0.apy / 100,
                    isActive: $0.isActive,
                    chainId: $0.chainId,
                    maxFeeNative: $0.maxFeeNative,
                    maxFeeUSD: $0.maxFeeUSD
                )
            }
        } catch {
            guard let cachedMarkets = yieldMarketsRepository.markets() else {
                return []
            }

            return cachedMarkets.markets.compactMap {
                return YieldModuleMarketInfo(
                    tokenContractAddress: $0.tokenContractAddress,
                    apy: $0.apy / 100,
                    isActive: $0.isActive,
                    chainId: $0.chainId,
                    maxFeeNative: $0.maxFeeNative,
                    maxFeeUSD: $0.maxFeeUSD
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
                chainId: $0.chainId,
                maxFeeNative: $0.maxFeeNative,
                maxFeeUSD: $0.maxFeeUSD
            )
        }
        yieldMarketsRepository.store(
            markets: CachedYieldModuleMarkets(markets: marketsToStore, lastUpdated: response.lastUpdatedAt)
        )
    }
}

private extension CommonYieldModuleNetworkManager {
    enum Constants {
        static let temporaryDefaultMaxNetworkFee = BigUInt(1) // will be removed in the future [REDACTED_INFO]
    }
}

private struct YieldModuleNetworkManagerKey: InjectionKey {
    static var currentValue: YieldModuleNetworkManager = {
        let apiType: YieldModuleAPIType = AppEnvironment.current.isProduction
            ? .prod
            : FeatureStorage.instance.yieldModuleAPIType

        let manager = CommonYieldModuleNetworkManager(
            yieldModuleAPIService: CommonYieldModuleAPIService(
                provider: .init(
                    configuration: .ephemeralConfiguration,
                    additionalPlugins: [
                        YieldModuleAuthorizationPlugin(),
                    ]
                ),
                yieldModuleAPIType: apiType
            ),
            yieldMarketsRepository: CommonYieldModuleMarketsRepository(),
            yieldModuleChartManager: CommonYieldModuleChartManager()
        )
        return manager
    }()
}

extension InjectedValues {
    var yieldModuleNetworkManager: YieldModuleNetworkManager {
        get { Self[YieldModuleNetworkManagerKey.self] }
        set { Self[YieldModuleNetworkManagerKey.self] = newValue }
    }
}
