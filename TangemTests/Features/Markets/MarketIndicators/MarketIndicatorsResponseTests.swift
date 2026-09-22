//
//  MarketIndicatorsResponseTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MarketsDTO.MarketIndicators.Response", .tags(.marketIndicators))
struct MarketIndicatorsResponseTests {
    /// The payloads below are the examples the backend publishes for `GET /api/v1/market-indicators`,
    /// read through the key strategy `CommonTangemApiService` decodes every response with.
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    @Test("Reads every field of a full response")
    func decodesFullResponse() throws {
        let json = """
        {
            "total_market_cap": 1799552403821,
            "market_cap_change_percentage_24h": -1.31,
            "fear_greed_value": 42,
            "fear_greed_classification": "Fear",
            "altcoin_index_value": 30,
            "altcoin_index_classification": "Bitcoin Strength"
        }
        """

        let response = try decode(json)

        #expect(response.totalMarketCap == 1_799_552_403_821)
        #expect(response.marketCapChangePercentage24H == Decimal(string: "-1.31"))
        #expect(response.fearGreedValue == 42)
        #expect(response.fearGreedClassification == "Fear")
        #expect(response.altcoinIndexValue == 30)
        #expect(response.altcoinIndexClassification == "Bitcoin Strength")
    }

    @Test("Reads a response whose indicators the backend could not refresh")
    func decodesEmptyResponse() throws {
        let json = """
        {
            "total_market_cap": null,
            "market_cap_change_percentage_24h": null,
            "fear_greed_value": null,
            "fear_greed_classification": null,
            "altcoin_index_value": null,
            "altcoin_index_classification": null
        }
        """

        let response = try decode(json)

        #expect(response.totalMarketCap == nil)
        #expect(response.marketCapChangePercentage24H == nil)
        #expect(response.fearGreedValue == nil)
        #expect(response.fearGreedClassification == nil)
        #expect(response.altcoinIndexValue == nil)
        #expect(response.altcoinIndexClassification == nil)
    }

    // MARK: - Helpers

    private func decode(_ json: String) throws -> MarketsDTO.MarketIndicators.Response {
        try decoder.decode(MarketsDTO.MarketIndicators.Response.self, from: Data(json.utf8))
    }
}
