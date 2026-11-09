//
//  PolymarketOrderSideTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
@testable import TangemPolymarket

@Suite("Polymarket order side per endpoint", .timeLimit(.minutes(1)))
struct PolymarketOrderSideTests {
    // MARK: - The book price

    @Test("A buy is priced off the sell side of the book, the side it takes its fill from")
    func buyIsPricedOffTheSellSide() throws {
        let query = try Self.priceQuery(orderSide: .buy)

        #expect(query[Self.tokenIdKey] as? String == Self.tokenId)
        #expect(query[Self.sideKey] as? String == "SELL")
        #expect(query.count == 2)
    }

    @Test("A sale is priced off the buy side of the book, the side it takes its fill from")
    func saleIsPricedOffTheBuySide() throws {
        let query = try Self.priceQuery(orderSide: .sell)

        #expect(query[Self.tokenIdKey] as? String == Self.tokenId)
        #expect(query[Self.sideKey] as? String == "BUY")
        #expect(query.count == 2)
    }

    // MARK: - The order

    @Test("The signature counts the side the way the exchange contract does")
    func signatureCountsTheOrderSide() {
        #expect(PolymarketOrderSide.buy.wireValue == 0)
        #expect(PolymarketOrderSide.sell.wireValue == 1)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderSideTests {
    static let baseURL = URL(string: "https://clob.polymarket.com")!
    static let tokenId = "1116017998421700000000000000000000000000000000000000000000000000047"

    static let tokenIdKey = "token_id"
    static let sideKey = "side"

    enum TestError: Error {
        case notRequestParameters
    }

    static func priceQuery(orderSide: PolymarketOrderSide) throws -> [String: Any] {
        let target = PolymarketCLOBTarget(
            baseURL: baseURL,
            target: .price(tokenId: tokenId, orderSide: orderSide),
            authHeaders: [:]
        )

        guard case .requestParameters(let parameters, _) = target.task else {
            throw TestError.notRequestParameters
        }

        return parameters
    }
}
