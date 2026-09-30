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

@Suite("Polymarket order side per endpoint")
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

    @Test("The price probe never asks for the side the user takes")
    func priceProbeNeverAsksForTheOrderSide() throws {
        for orderSide in [PolymarketOrderSide.buy, .sell] {
            let query = try Self.priceQuery(orderSide: orderSide)

            #expect(query[Self.sideKey] as? String != orderSide.rawValue)
        }
    }

    // MARK: - The quote

    @Test("The quote is asked for the side the user takes")
    func quoteStatesTheOrderSide() {
        #expect(Self.quoteBody(side: .buy).side == "BUY")
        #expect(Self.quoteBody(side: .sell).side == "SELL")
    }

    // MARK: - The order

    @Test("The order is placed on the side the user takes, with the legs that side spends and receives")
    func orderStatesTheOrderSide() {
        let buy = Self.placeOrderBody(side: .buy)

        #expect(buy.order.side == "BUY")
        #expect(buy.order.makerAmount == "72000000")
        #expect(buy.order.takerAmount == "97959180")

        let sale = Self.placeOrderBody(side: .sell)

        #expect(sale.order.side == "SELL")
        #expect(sale.order.makerAmount == "97959180")
        #expect(sale.order.takerAmount == "72000000")
    }

    @Test("The signature counts the side the way the exchange contract does")
    func signatureCountsTheOrderSide() {
        #expect(PolymarketOrderSide.buy.wireValue == 0)
        #expect(PolymarketOrderSide.sell.wireValue == 1)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderSideTests {
    static let baseURL = URL(string: "https://clob.polymarket.com")!
    static let depositWallet = "0x5A057dc6394196fBa51D84457DA3FB8FA241Fc20"
    static let tokenId = "1116017998421700000000000000000000000000000000000000000000000000047"

    static let tokenIdKey = "token_id"
    static let sideKey = "side"

    static let notional: Decimal = 72
    static let shares = Decimal(string: "97.95918")!

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

    static func quoteBody(side: PolymarketOrderSide) -> PolymarketDTO.OrderQuoteRequestBody {
        let request = PolymarketOrderQuoteRequest(
            marketId: "m1",
            assetId: tokenId,
            side: side,
            amount: notional,
            slippagePercent: Decimal(string: "0.25")!
        )

        return PolymarketMapper().mapOrderQuoteRequest(request)
    }

    static func placeOrderBody(side: PolymarketOrderSide) -> PolymarketDTO.PlaceOrderRequestBody {
        let order = PolymarketOrderFactory.make(
            quote: .stub(side: side, notional: notional, shares: shares),
            assetId: tokenId,
            depositWalletAddress: depositWallet
        )

        let signedOrder = PolymarketSignedOrder(order: order, signature: "0xdeadbeef", isNegRisk: false)

        return PolymarketMapper().mapPlaceOrderRequest(signedOrder, apiKey: "api-key")
    }
}
