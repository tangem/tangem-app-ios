//
//  BannerPromotionDecodingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("BannerPromotion decoding", .tags(.promotionCampaigns))
struct BannerPromotionDecodingTests {
    /// Mirrors the /promotion payload; dates use the fractional-seconds ISO8601 format
    /// that `CommonTangemApiService` configures its decoder with.
    private static let json = """
    {
      "promotions": [
        {
          "name": "yield-apr-boost",
          "all": {
            "timeline": {
              "start": "2026-07-01T00:00:00.000Z",
              "end": "2026-08-01T12:30:45.500Z"
            },
            "tokens": [
              {
                "tokenAddress": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
                "tokenSymbol": "USDC",
                "tokenName": "USD Coin",
                "networkId": "ethereum"
              }
            ],
            "status": "active",
            "link": "https://tangem.com/promo"
          }
        },
        {
          "name": "cashback-campaign",
          "all": {
            "timeline": {
              "start": "2026-07-01T00:00:00.000Z",
              "end": "2026-08-01T00:00:00.000Z"
            },
            "tokens": [],
            "status": "pending"
          }
        }
      ]
    }
    """

    private func decodeResponse() throws -> BannerPromotion.Response {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return try decoder.decode(BannerPromotion.Response.self, from: Data(Self.json.utf8))
    }

    @Test("Timeline dates parse with fractional seconds through the API decoder strategy")
    func timelineDatesParse() throws {
        let promotion = try #require(decodeResponse().promotions.first)

        #expect(promotion.name == "yield-apr-boost")
        #expect(promotion.all.timeline.start == Date(timeIntervalSince1970: 1_782_864_000))
        #expect(promotion.all.timeline.end == Date(timeIntervalSince1970: 1_785_587_445.5))
    }

    @Test("Tokens, status and link map from the payload")
    func fieldsMap() throws {
        let response = try decodeResponse()
        let yieldPromotion = try #require(response.promotions.first)

        #expect(yieldPromotion.all.status == .active)
        #expect(yieldPromotion.all.link == "https://tangem.com/promo")

        let token = try #require(yieldPromotion.all.tokens.first)
        #expect(token.tokenAddress == "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
        #expect(token.tokenSymbol == "USDC")
        #expect(token.tokenName == "USD Coin")
        #expect(token.networkId == "ethereum")
    }

    @Test("Absent link decodes to nil and status maps its raw value")
    func absentLinkDecodesToNil() throws {
        let cashbackPromotion = try #require(decodeResponse().promotions.last)

        #expect(cashbackPromotion.name == "cashback-campaign")
        #expect(cashbackPromotion.all.link == nil)
        #expect(cashbackPromotion.all.status == .pending)
        #expect(cashbackPromotion.all.tokens.isEmpty)
    }
}
