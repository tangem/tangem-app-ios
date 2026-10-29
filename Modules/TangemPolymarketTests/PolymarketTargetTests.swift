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

@Suite("PolymarketTarget", .timeLimit(.minutes(1)))
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

    @Test("A cursor, when there is one, picks the next page")
    func pageFromCursor() {
        #expect(PolymarketPositionsPageRequest<PolymarketPositionsRequest.Sort>.page(limit: 20, cursor: nil) == .first(limit: 20))
        #expect(PolymarketPositionsPageRequest<PolymarketPositionsRequest.Sort>.page(limit: 20, cursor: "c") == .next(cursor: "c"))
    }
}
