//
//  LendingApyHistoryProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("Lending APY history")
struct LendingApyHistoryProviderTests {
    private static let chartEnd = Date(timeIntervalSince1970: 1_793_664_000)

    @Test("Each period asks for its own window with buckets small enough for a full chart", arguments: [
        (LendingApyHistoryPeriod.oneMonth, YieldModuleDTO.ChartWindow.lastMonth, 1),
        (.threeMonths, .lastYear, 3),
        (.sixMonths, .lastYear, 6),
    ])
    func request(period: LendingApyHistoryPeriod, window: YieldModuleDTO.ChartWindow, bucketSizeDays: Int) async throws {
        let api = ChartAPIServiceSpy(chart: try Self.chart(daysAgo: [10], apys: [5], average: 5))

        _ = try await makeSUT(api: api).history(for: period)

        #expect(api.requests.map(\.window) == [window])
        #expect(api.requests.map(\.bucketSizeDays) == [bucketSizeDays])
    }

    @Test("One month shows the chart as it comes, with its own average")
    func oneMonthAsItComes() async throws {
        let api = ChartAPIServiceSpy(chart: try Self.chart(daysAgo: [80, 40, 10], apys: [3, 4, 5], average: 4.2))

        let data = try await makeSUT(api: api).history(for: .oneMonth)

        #expect(data.buckets == [3, 4, 5])
        #expect(data.averageApy == 4.2)
    }

    @Test("Three months are the last three months of the yearly chart, as the backend has no quarterly Aave window")
    func threeMonthsSliceTheYear() async throws {
        let api = ChartAPIServiceSpy(chart: try Self.chart(daysAgo: [200, 120, 80, 1], apys: [9, 9, 4, 6], average: 7))

        let data = try await makeSUT(api: api).history(for: .threeMonths)

        #expect(data.buckets == [4, 6])
        #expect(data.averageApy == 5)
    }

    @Test("Six months are the last six months of the yearly chart, averaged and labelled by what is kept")
    func sixMonthsSliceTheYear() async throws {
        let api = ChartAPIServiceSpy(chart: try Self.chart(daysAgo: [300, 200, 150, 1], apys: [9, 9, 4, 6], average: 7))

        let data = try await makeSUT(api: api).history(for: .sixMonths)

        #expect(data.buckets == [4, 6])
        #expect(data.averageApy == 5)
        #expect(data.maxApy == 6)
        #expect(data.xTicks.keys.sorted() == [0, 1])
    }

    @Test("A chart with no data shows no bars and no month labels")
    func emptyChart() async throws {
        let api = ChartAPIServiceSpy(chart: try Self.chart(daysAgo: [], apys: [], average: 0))

        let data = try await makeSUT(api: api).history(for: .threeMonths)

        #expect(data.buckets.isEmpty)
        #expect(data.xTicks.isEmpty)
    }
}

// MARK: - Helpers

private extension LendingApyHistoryProviderTests {
    func makeSUT(api: ChartAPIServiceSpy) -> CommonLendingApyHistoryProvider {
        CommonLendingApyHistoryProvider(
            apiService: api,
            chainId: 1,
            wrappedNative: { "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2" }
        )
    }

    static func chart(daysAgo: [Int], apys: [Double], average: Double) throws -> YieldModuleDTO.Response.Chart {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = { (days: Int) in formatter.string(from: chartEnd.addingTimeInterval(-Double(days) * 86400)) }
        let buckets = zip(daysAgo, apys).enumerated().map { index, pair in
            #"{"bucketIndex":\#(index),"start":"\#(date(pair.0))","end":"\#(date(pair.0 - 1))","avgApy":"\#(pair.1)"}"#
        }
        let from = date(daysAgo.first ?? 30)
        let json = #"{"underlying":"0xc02a","chainId":1,"market":"AaveV3Ethereum","bucketSizeDays":1,"period":"LAST_YEAR","from":"\#(from)","to":"\#(date(0))","data":[\#(buckets.joined(separator: ","))],"avr":\#(average)}"#

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return try decoder.decode(YieldModuleDTO.Response.Chart.self, from: Data(json.utf8))
    }
}

// MARK: - Stubs

private struct StubError: Error {}

private final class ChartAPIServiceSpy: YieldModuleAPIService {
    struct Request: Equatable {
        let window: YieldModuleDTO.ChartWindow?
        let bucketSizeDays: Int?
    }

    private let chart: YieldModuleDTO.Response.Chart
    private let state = OSAllocatedUnfairLock(initialState: [Request]())

    init(chart: YieldModuleDTO.Response.Chart) {
        self.chart = chart
    }

    var requests: [Request] {
        state.withLock { $0 }
    }

    func getChart(
        tokenContractAddress: String,
        chainId: Int,
        window: YieldModuleDTO.ChartWindow?,
        bucketSizeDays: Int?
    ) async throws -> YieldModuleDTO.Response.Chart {
        state.withLock { $0.append(Request(window: window, bucketSizeDays: bucketSizeDays)) }
        return chart
    }

    func getIncentiveYieldMarkets(chainIDs: [String]?) async throws -> YieldModuleDTO.Response.MarketsInfo { throw StubError() }
    func getIncentives(chainId: Int, userAddress: String) async throws -> YieldModuleDTO.Response.IncentivesInfo? { throw StubError() }
    func getClaimCalldata(chainId: Int, userAddress: String) async throws -> YieldModuleDTO.Response.ClaimCalldata { throw StubError() }
    func getClaimHistory(chainId: Int, userAddress: String) async throws -> YieldModuleDTO.Response.ClaimHistory? { throw StubError() }
    func getAprHistory(chainId: Int, tokenAddress: String, days: Int) async throws -> YieldModuleDTO.Response.AprHistory { throw StubError() }
    func getTokenPositionInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleDTO.Response.PositionInfo { throw StubError() }
    func activate(tokenContractAddress: String, walletAddress: String, chainId: Int, userWalletId: String) async throws {}
    func deactivate(tokenContractAddress: String, walletAddress: String, chainId: Int) async throws {}
    func sendTransactionEvent(txHash: String, operation: String, userAddress: String?) async throws {}
}
