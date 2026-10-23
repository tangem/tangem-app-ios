//
//  PolymarketTargetTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Alamofire
import Moya
@testable import TangemPolymarket

@Suite("PolymarketTarget")
struct PolymarketTargetTests {
    private let baseURL = URL(string: "https://gateway.tangem.com")!
    private let walletId = "w1"

    private func target(_ target: PolymarketTarget.Target) -> PolymarketTarget {
        PolymarketTarget(baseURL: baseURL, walletId: walletId, target: target)
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
        PolymarketPositionsRequest(depositWalletAddress: "0xdead", page: .first(limit: 30))
    }

    private var closedPositionsRequest: PolymarketClosedPositionsRequest {
        PolymarketClosedPositionsRequest(depositWalletAddress: "0xdead", page: .first(limit: 30))
    }

    private var positionOutcomeRequest: PolymarketPositionOutcomeRequest {
        PolymarketPositionOutcomeRequest(
            depositWalletAddress: "0xdead",
            conditionId: "0x1",
            assetId: "a1"
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
        #expect(target(.closedPositions(closedPositionsRequest)).path == "api/predictions/v1/positions/closed")
        #expect(target(.positionOutcome(positionOutcomeRequest)).path == "api/predictions/v1/positions/outcome")
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
        #expect(target(.closedPositions(closedPositionsRequest)).method == .get)
        #expect(target(.positionOutcome(positionOutcomeRequest)).method == .get)
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

    @Test("Every read carries the wallet id, not just the ones tied to an account")
    func headers() {
        let expected = ["wallet-id": walletId]

        #expect(target(.categories(locale: nil)).headers == expected)
        #expect(target(.events(.init())).headers == expected)
        #expect(target(.event(id: "abc")).headers == expected)
        #expect(target(.search(.init(query: "q"))).headers == expected)
        #expect(target(.series).headers == expected)
        #expect(target(.seriesEvents(seriesId: "s1")).headers == expected)
        #expect(target(.orderQuote(quoteBody)).headers == expected)
        #expect(target(.positions(positionsRequest)).headers == expected)
        #expect(target(.closedPositions(closedPositionsRequest)).headers == expected)
        #expect(target(.positionOutcome(positionOutcomeRequest)).headers == expected)
    }

    @Test("positions: the first page asks for a size and leaves the order to the backend")
    func positionsFirstPageParameters() throws {
        let parameters = try queryParameters(target(.positions(positionsRequest)).task)

        #expect(parameters["depositWalletAddress"] as? String == "0xdead")
        #expect(parameters["limit"] as? Int == 30)
        #expect(parameters.count == 2)
    }

    @Test("positions: a next page carries only the cursor")
    func positionsNextPageParameters() throws {
        let request = PolymarketPositionsRequest(depositWalletAddress: "0xdead", page: .next(cursor: "opaque=="))
        let parameters = try queryParameters(target(.positions(request)).task)

        #expect(parameters["depositWalletAddress"] as? String == "0xdead")
        #expect(parameters["cursor"] as? String == "opaque==")
        #expect(parameters.count == 2)
    }

    @Test("positions: an explicit order goes with the first page only")
    func positionsSortedFirstPageParameters() throws {
        let request = PolymarketPositionsRequest(
            depositWalletAddress: "0xdead",
            page: .first(limit: 30, sort: .totalPnl, ascending: true)
        )
        let parameters = try queryParameters(target(.positions(request)).task)

        #expect(parameters["sort"] as? String == "totalPnl")
        #expect(parameters["ascending"] as? Bool == true)
        #expect(parameters["limit"] as? Int == 30)
        #expect(parameters.count == 4)
    }

    @Test("closed positions: the first page asks for a size and leaves the order to the backend")
    func closedPositionsFirstPageParameters() throws {
        let parameters = try queryParameters(target(.closedPositions(closedPositionsRequest)).task)

        #expect(parameters["depositWalletAddress"] as? String == "0xdead")
        #expect(parameters["limit"] as? Int == 30)
        #expect(parameters.count == 2)
    }

    @Test("closed positions: a next page carries only the cursor")
    func closedPositionsNextPageParameters() throws {
        let request = PolymarketClosedPositionsRequest(depositWalletAddress: "0xdead", page: .next(cursor: "c2"))
        let parameters = try queryParameters(target(.closedPositions(request)).task)

        #expect(parameters["depositWalletAddress"] as? String == "0xdead")
        #expect(parameters["cursor"] as? String == "c2")
        #expect(parameters.count == 2)
    }

    @Test("A cursor, when there is one, picks the next page")
    func pageFromCursor() {
        #expect(PolymarketPositionsPageRequest<PolymarketPositionsRequest.Sort>.page(limit: 20, cursor: nil) == .first(limit: 20))
        #expect(PolymarketPositionsPageRequest<PolymarketPositionsRequest.Sort>.page(limit: 20, cursor: "c") == .next(cursor: "c"))
    }

    @Test("position outcome: the market and the outcome identify the row")
    func positionOutcomeParameters() throws {
        let parameters = try queryParameters(target(.positionOutcome(positionOutcomeRequest)).task)

        #expect(parameters["depositWalletAddress"] as? String == "0xdead")
        #expect(parameters["conditionId"] as? String == "0x1")
        #expect(parameters["assetId"] as? String == "a1")
        #expect(parameters.count == 3)
    }
}
