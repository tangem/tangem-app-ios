//
//  YieldModuleNetworkManagerMarketsLoadStateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import Tangem

@Suite("Yield Mode markets load state", .timeLimit(.minutes(1)))
struct YieldModuleNetworkManagerMarketsLoadStateTests {
    @Test("A successful response is reported as loaded")
    func successfulResponseIsLoaded() async {
        let result = await loadMarkets(marketsResult: .success(makeMarketsInfo()))

        #expect(result.states == [.idle, .loading, .loaded])
    }

    @Test("A failed request is reported as failed even though the cached markets are still published")
    func failedRequestIsFailed() async {
        let result = await loadMarkets(
            marketsResult: .failure(StubError()),
            cachedMarkets: makeCachedMarkets(tokenContractAddress: "0xcached")
        )

        #expect(result.states == [.idle, .loading, .failed])
        #expect(result.marketAddresses == ["0xcached"])
    }
}

// MARK: - Helpers

private extension YieldModuleNetworkManagerMarketsLoadStateTests {
    func makeSUT(
        marketsResult: Result<YieldModuleDTO.Response.MarketsInfo, Error>,
        cachedMarkets: CachedYieldModuleMarkets? = nil
    ) -> CommonYieldModuleNetworkManager {
        CommonYieldModuleNetworkManager(
            yieldModuleAPIService: YieldModuleAPIServiceStub(marketsResult: marketsResult),
            yieldMarketsRepository: YieldModuleMarketsRepositoryStub(cachedMarkets: cachedMarkets),
            yieldModuleChartManager: CommonYieldModuleChartManager()
        )
    }

    func loadMarkets(
        marketsResult: Result<YieldModuleDTO.Response.MarketsInfo, Error>,
        cachedMarkets: CachedYieldModuleMarkets? = nil
    ) async -> (states: [YieldModuleMarketsLoadState], marketAddresses: [String]) {
        await InjectedDependenciesIsolation.shared.run {
            let originalRepository = InjectedValues[\.userWalletRepository]
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [])
            defer { InjectedValues[\.userWalletRepository] = originalRepository }

            let sut = makeSUT(marketsResult: marketsResult, cachedMarkets: cachedMarkets)

            var cancellable: AnyCancellable?
            defer { cancellable?.cancel() }

            return await withCheckedContinuation { continuation in
                cancellable = sut.marketsLoadStatePublisher
                    .scan([YieldModuleMarketsLoadState]()) { $0 + [$1] }
                    .first { $0.last == .loaded || $0.last == .failed }
                    .sink { states in
                        continuation.resume(returning: (states, sut.markets.map(\.tokenContractAddress)))
                    }

                sut.updateMarkets()
            }
        }
    }

    func makeMarketsInfo() -> YieldModuleDTO.Response.MarketsInfo {
        YieldModuleDTO.Response.MarketsInfo(tokens: [], lastUpdatedAt: Date())
    }

    func makeCachedMarkets(tokenContractAddress: String = "0xtoken") -> CachedYieldModuleMarkets {
        let market = CachedYieldModuleMarket(
            tokenContractAddress: tokenContractAddress,
            apy: 3,
            isActive: true,
            chainId: 1,
            maxFeeNative: nil,
            maxFeeUSD: nil
        )

        return CachedYieldModuleMarkets(markets: [market], lastUpdated: Date())
    }
}

// MARK: - Stubs

private struct StubError: Error {}

private final class YieldModuleMarketsRepositoryStub: YieldModuleMarketsRepository {
    private let cachedMarkets: CachedYieldModuleMarkets?

    init(cachedMarkets: CachedYieldModuleMarkets?) {
        self.cachedMarkets = cachedMarkets
    }

    func store(markets: CachedYieldModuleMarkets) {}

    func markets() -> CachedYieldModuleMarkets? {
        cachedMarkets
    }

    func marketInfo(for contractAddress: String) -> CachedYieldModuleMarket? {
        nil
    }
}

private struct YieldModuleAPIServiceStub: YieldModuleAPIService {
    let marketsResult: Result<YieldModuleDTO.Response.MarketsInfo, Error>

    func getIncentiveYieldMarkets(chainIDs: [String]?) async throws -> YieldModuleDTO.Response.MarketsInfo {
        try marketsResult.get()
    }

    func getIncentives(chainId: Int, userAddress: String) async throws -> YieldModuleDTO.Response.IncentivesInfo? {
        throw StubError()
    }

    func getClaimCalldata(chainId: Int, userAddress: String) async throws -> YieldModuleDTO.Response.ClaimCalldata {
        throw StubError()
    }

    func getClaimHistory(chainId: Int, userAddress: String) async throws -> YieldModuleDTO.Response.ClaimHistory? {
        throw StubError()
    }

    func getAprHistory(chainId: Int, tokenAddress: String, days: Int) async throws -> YieldModuleDTO.Response.AprHistory {
        throw StubError()
    }

    func getTokenPositionInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleDTO.Response.PositionInfo {
        throw StubError()
    }

    func getChart(
        tokenContractAddress: String,
        chainId: Int,
        window: YieldModuleDTO.ChartWindow?,
        bucketSizeDays: Int?
    ) async throws -> YieldModuleDTO.Response.Chart {
        throw StubError()
    }

    func activate(tokenContractAddress: String, walletAddress: String, chainId: Int, userWalletId: String) async throws {}

    func deactivate(tokenContractAddress: String, walletAddress: String, chainId: Int) async throws {}

    func sendTransactionEvent(txHash: String, operation: String, userAddress: String?) async throws {}
}
