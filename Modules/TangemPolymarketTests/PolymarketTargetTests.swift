//
//  PolymarketTargetTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
@testable import TangemPolymarket

@Suite("PolymarketTarget")
struct PolymarketTargetTests {
    private let baseURL = URL(string: "https://gateway.tangem.com")!

    private func target(_ target: PolymarketTarget.Target) -> PolymarketTarget {
        PolymarketTarget(baseURL: baseURL, target: target)
    }

    private func isRequestPlain(_ task: Moya.Task) -> Bool {
        if case .requestPlain = task { return true }
        return false
    }

    private func queryParameters(_ task: Moya.Task) throws -> [String: Any] {
        guard case .requestParameters(let parameters, _) = task else {
            throw TestError.notRequestParameters
        }
        return parameters
    }

    private enum TestError: Error { case notRequestParameters }

    private var positionsRequest: PolymarketPositionsRequest {
        PolymarketPositionsRequest(
            depositWalletAddress: "0xdead",
            walletId: "w1",
            sort: .cashPnl,
            ascending: false,
            limit: 30,
            offset: 60
        )
    }

    private var quoteBody: PolymarketDTO.OrderQuoteRequestBody {
        PolymarketDTO.OrderQuoteRequestBody(marketId: "m1", assetId: "a1", side: "BUY", amount: "10", slippage: "0.25")
    }

    @Test("Paths")
    func paths() {
        #expect(target(.categories(locale: nil)).path == "api/predictions/v1/categories")
        #expect(target(.events(.init())).path == "api/predictions/v1/events")
        #expect(target(.event(id: "abc")).path == "api/predictions/v1/events/abc")
        #expect(target(.search(.init(query: "q"))).path == "api/predictions/v1/search")
        #expect(target(.series).path == "api/predictions/v1/series")
        #expect(target(.seriesEvents(seriesId: "s1")).path == "api/predictions/v1/series/s1/events")
        #expect(target(.orderQuote(quoteBody)).path == "api/predictions/v1/orders/quote")
        #expect(target(.positions(positionsRequest)).path == "api/predictions/v1/positions")
    }

    @Test("Discovery reads over GET, the quote is posted")
    func method() {
        #expect(target(.categories(locale: nil)).method == .get)
        #expect(target(.events(.init())).method == .get)
        #expect(target(.event(id: "abc")).method == .get)
        #expect(target(.search(.init(query: "q"))).method == .get)
        #expect(target(.series).method == .get)
        #expect(target(.seriesEvents(seriesId: "s1")).method == .get)
        #expect(target(.orderQuote(quoteBody)).method == .post)
        #expect(target(.positions(positionsRequest)).method == .get)
    }

    @Test("categories: locale omitted when nil, sent when present")
    func categoriesParameters() throws {
        #expect(isRequestPlain(target(.categories(locale: nil)).task))

        let parameters = try queryParameters(target(.categories(locale: "en")).task)
        #expect(parameters["locale"] as? String == "en")
        #expect(parameters.count == 1)
    }

    @Test("events: only non-nil fields become query items")
    func eventsParameters() throws {
        #expect(isRequestPlain(target(.events(.init())).task))

        let request = PolymarketEventsRequest(category: 7, sort: .volume, limit: 20)
        let parameters = try queryParameters(target(.events(request)).task)
        #expect(parameters["category"] as? Int == 7)
        #expect(parameters["sort"] as? String == "volume")
        #expect(parameters["limit"] as? Int == 20)
        #expect(parameters["ascending"] == nil)
        #expect(parameters["cursor"] == nil)
    }

    @Test("search: query always present, page/limit guarded")
    func searchParameters() throws {
        let minimal = try queryParameters(target(.search(.init(query: "btc"))).task)
        #expect(minimal["query"] as? String == "btc")
        #expect(minimal["limit"] == nil)
        #expect(minimal["page"] == nil)

        let full = try queryParameters(target(.search(.init(query: "btc", limit: 10, page: 2))).task)
        #expect(full["limit"] as? Int == 10)
        #expect(full["page"] as? Int == 2)
    }

    @Test("Only positions carry a target-specific header")
    func headers() {
        #expect(target(.series).headers == nil)
        #expect(target(.orderQuote(quoteBody)).headers == nil)
        #expect(target(.positions(positionsRequest)).headers == ["wallet-id": "w1"])
    }

    @Test("positions: the whole page window goes into the query")
    func positionsParameters() throws {
        let parameters = try queryParameters(target(.positions(positionsRequest)).task)

        #expect(parameters["depositWalletAddress"] as? String == "0xdead")
        #expect(parameters["sort"] as? String == "cashPnl")
        #expect(parameters["ascending"] as? Bool == false)
        #expect(parameters["limit"] as? Int == 30)
        #expect(parameters["offset"] as? Int == 60)
        #expect(parameters.count == 5)
    }
}
